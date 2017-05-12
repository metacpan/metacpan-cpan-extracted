## -*- Mode: CPerl -*-
## File: DiaColloDB::MultiMapFile.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, integer->integer* multimap file, e.g. for expansion indices

package DiaColloDB::MultiMapFile;
use DiaColloDB::Logger;
use DiaColloDB::Persistent;
use DiaColloDB::Utils qw(:fcntl :file :json :pack);
use Fcntl qw(:DEFAULT :seek);
use File::Basename qw(basename dirname);
use version;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Persistent);

##==============================================================================
## Constructors etc.

## $mmf = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- basic options
##    base => $base,       ##-- database basename; use files "${base}.ma", "${base}.mb", "${base}.hdr"
##    perms => $perms,     ##-- default: 0666 & ~umask
##    flags => $flags,     ##-- default: 'r'
##    pack_i => $pack_i,   ##-- integer pack template (default='N')
##    size => $size,       ##-- number of mapped , like scalar(@data)
##    logCompat => $level, ##-- log-level for compatibility warnings (default='warn')
##    ##
##    ##-- in-memory construction
##    a2b => \@a2b,        ##-- maps source integers to (packed) target integer-sets: [$a] => pack("${pack_i}*", @bs)
##    ##
##    ##-- computed pack templates and lengths (after open())
##    pack_a => $pack_a,   ##-- "($pack_i)[2]"
##    pack_b => $pack_a,   ##-- "($pack_i)*"
##    len_i => $len_i,     ##-- bytes::length(pack($pack_i,0))
##    len_a => $len_a,     ##-- bytes::length(pack($pack_a,0))
##    ##
##    ##-- filehandles (after open())
##    afh => $afh,         ##-- $base.ma : [$a]      => pack(${pack_a}, $bidx_a, $blen_a) : $byte_offset_in_bfh = $len_i*$bidx_a
##    bfh => $bfh,         ##-- $base.mb : [$bidx_a] => pack(${pack_b}, @targets_for_a)   : $byte_length_in_bfh = $len_i*$blen_a
##   )
sub new {
  my $that = shift;
  my $mmf  = bless({
		    base => undef,
		    perms => (0666 & ~umask),
		    flags => 'r',
		    size => 0,
		    pack_i => 'N',
		    version => $DiaColloDB::VERSION,
		    logCompat => 'warn',

		    a2b=>[],

		    #len_i => undef,

		    #afh =>undef,
		    #bfh =>undef,

		    @_, ##-- user arguments
		   },
		   ref($that)||$that);
  $mmf->{class} = ref($mmf);
  $mmf->{a2b}    //= [];
  return defined($mmf->{base}) ? $mmf->open($mmf->{base}) : $mmf;
}

sub DESTROY {
  $_[0]->close() if ($_[0]->opened);
}

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: open/close (file)

## $mmf_or_undef = $mmf->open($base,$flags)
## $mmf_or_undef = $mmf->open($base)
## $mmf_or_undef = $mmf->open()
sub open {
  my ($mmf,$base,$flags) = @_;
  $base  //= $mmf->{base};
  $flags //= $mmf->{flags};
  $mmf->close() if ($mmf->opened);
  $mmf->{base}  = $base;
  $mmf->{flags} = $flags = fcflags($flags);
  my ($hdr); ##-- save header, for version-checking
  if (fcread($flags) && !fctrunc($flags)) {
    $hdr = $mmf->readHeader()
      or $mmf->logconess("failed to read header data from '$mmf->{base}.hdr': $!");
    $mmf->loadHeaderData($hdr)
      or $mmf->logconess("failed to instantiate header from '$mmf->{base}.hdr': $!");
  }

  ##-- check compatibility
  my $min_version = qv(0.09.000);
  if ($hdr && (!defined($hdr->{version}) || version->parse($hdr->{version}) < $min_version)) {
    $mmf->vlog($mmf->{logCompat}, "using compatibility mode for $mmf->{base}.*; consider running \`dcdb-upgrade.perl ", dirname($mmf->{base}), "\'");
    DiaColloDB::Compat->usecompat('v0_08');
    bless($mmf, 'DiaColloDB::Compat::v0_08::MultiMapFile');
    $mmf->{version} = $hdr->{version};
    return $mmf->open($base,$flags);
  }

  ##-- open underlying files
  $mmf->{afh} = fcopen("$base.ma", $flags, $mmf->{perms})
    or $mmf->logconfess("open failed for $base.ma: $!");
  $mmf->{bfh} = fcopen("$base.mb", $flags, $mmf->{perms})
    or $mmf->logconfess("open failed for $base.mb: $!");
  binmode($_,':raw') foreach (@$mmf{qw(afh bfh)});

  ##-- computed pack-templates & lengths
  $mmf->{pack_a} = $mmf->{pack_i}."[2]";
  $mmf->{pack_b} = $mmf->{pack_i}."*";
  $mmf->{len_i}  = packsize($mmf->{pack_i});
  $mmf->{len_a}  = packsize($mmf->{pack_a});

  return $mmf;
}

## $mmf_or_undef = $mmf->close()
sub close {
  my $mmf = shift;
  if ($mmf->opened && fcwrite($mmf->{flags})) {
    $mmf->flush() or return undef;
  }
  !defined($mmf->{afh}) or $mmf->{afh}->close() or return undef;
  !defined($mmf->{bfh}) or $mmf->{bfh}->close() or return undef;
  $mmf->{a2b} //= [],
  undef $mmf->{base};
  return $mmf;
}

## $bool = $mmf->opened()
sub opened {
  my $mmf = shift;
  return
    (
     #defined($mmf->{base}) &&
     defined($mmf->{afh})
     && defined($mmf->{bfh})
    );
}

## $bool = $enum->reopen()
##  + re-opens datafiles
sub reopen {
  my $mmf   = shift;
  my $base = $mmf->{base} || "$mmf";
  return (
	  $mmf->opened
	  && fh_reopen($mmf->{afh}, "$base.ma")
	  && fh_reopen($mmf->{bfh}, "$base.mb")
	 );
}


## $bool = $mmf->dirty()
##  + returns true iff some in-memory structures haven't been flushed to disk
sub dirty {
  return @{$_[0]{a2b}};
}

## $bool = $mmf->flush()
##  + flush in-memory structures to disk
##  + clobbers any old disk-file contents with in-memory maps
##  + file must be opened in write-mode
##  + invalidates any old references to {a2b} (but doesn't empty them if you need to keep a reference)
sub flush {
  my $mmf = shift;
  return undef if (!$mmf->opened || !fcwrite($mmf->{flags}));
  return $mmf if (!$mmf->dirty);

  ##-- save header
  $mmf->saveHeader()
    or $mmf->logconfess("flush(): failed to store header $mmf->{base}.hdr: $!");

  #use bytes; ##-- deprecated in perl v5.18.2
  my ($afh,$bfh) = @$mmf{qw(afh bfh)};
  $afh->seek(0,SEEK_SET);
  $bfh->seek(0,SEEK_SET);

  ##-- dump datafiles $base.ma, $base.mb
  my ($a2b,$pack_a,$len_i) = @$mmf{qw(a2b pack_a len_i)};
  my $bidx  = 0;
  my $ai    = 0;
  my ($blen);
  foreach (@$a2b) {
    $_    //= '';
    $blen   = length($_)/$len_i;
    $afh->print(pack($pack_a, $bidx, $blen))
      or $mmf->logconfess("flush(): failed to write source record for a=$ai to $mmf->{base}.ma");
    $bfh->print($_)
      or $mmf->logconfess("flush(): failed to write targets for a=$ai to $mmf->{base}.mb");
    ++$ai;
    $bidx += $blen;
  }

  ##-- truncate datafiles at current position
  CORE::truncate($afh, $afh->tell());
  CORE::truncate($bfh, $bfh->tell());

  ##-- clear in-memory structures (but don't clobber existing references)
  $mmf->{a2b} = [];

  $mmf->reopen() or return undef if ((caller(1))[3] !~ /::close$/);
  return $mmf;
}


##--------------------------------------------------------------
## I/O: memory <-> file

## \@a2b = $mmf->toArray()
sub toArray {
  my $mmf = shift;
  return $mmf->{a2b} if (!$mmf->opened);

  #use bytes; ##-- deprecated in perl v5.18.2
  my ($afh,$bfh,$pack_a,$len_a,$pack_i,$len_i) = @$mmf{qw(afh bfh pack_a len_a pack_i len_i)};
  my @a2b    = qw();

  ##-- ye olde loope
  my ($bidx,$blen,$buf);
  for (CORE::seek($afh,0,SEEK_SET); !eof($afh); ) {
    ##-- get position, length
    CORE::read($afh,$buf,$len_a)==$len_a
	or $mmf->logconfess("toArray(): read() failed for $mmf->{base}.ma item ", scalar(@a2b));
    ($bidx,$blen) = unpack($pack_a,$buf);

    ##-- read targets
    $blen *= $len_i;
    CORE::seek($bfh,$bidx*$len_i,SEEK_SET);
    CORE::read($bfh,$buf,$blen)==$blen
	or $mmf->logconfess("toArray(): read() failed for $blen byte(s) on $mmf->{base}.mb at logical record $bidx, item ", scalar(@a2b));
    push(@a2b,$buf);
  }
  push(@a2b, @{$mmf->{a2b}}[scalar(@a2b)..$#{$mmf->{a2b}}]) if ($mmf->dirty);
  return \@a2b;
}

## $mmf = $mmf->fromArray(\@a2b)
##  + clobbers $mmf contents, steals \@a2b
sub fromArray {
  my ($mmf,$a2b) = @_;
  $mmf->{a2b}  = $a2b;
  $mmf->{size} = scalar(@{$mmf->{a2b}});
  return $mmf;
}

## $bool = $mmf->load()
##  + loads files to memory; must be opened
sub load {
  my $mmf = shift;
  return $mmf->fromArray($mmf->toArray);
}

## $mmf = $mmf->save()
## $mmf = $mmf->save($base)
##  + saves multimap to $base; really just a wrapper for open() and flush()
sub save {
  my ($mmf,$base) = @_;
  $mmf->open($base,'rw') if (defined($base));
  $mmf->logconfess("save(): cannot save un-opened multimap") if (!$mmf->opened);
  $mmf->flush() or $mmf->logconfess("save(): failed to flush to $mmf->{base}: $!");
  return $mmf;
}


##--------------------------------------------------------------
## I/O: header
##  + see also DiaColloDB::Persistent

## @keys = $coldb->headerKeys()
##  + keys to save as header
sub headerKeys {
  return (qw(version), grep {!ref($_[0]{$_}) && $_ !~ m{^(?:flags|perms|base|version)$}} keys %{$_[0]});
}

## $bool = $CLASS_OR_OBJECT->loadHeader()
##  + wraps $CLASS_OR_OBJECT->loadHeaderFile($CLASS_OR_OBJ->headerFile())
##  + INHERITED from DiaColloDB::Persistent

## $bool = $mmf->loadHeaderData($hdr)
sub loadHeaderData {
  my ($mmf,$hdr) = @_;
  if (!defined($hdr) && (fcflags($mmf->{flags})&O_CREAT) != O_CREAT) {
    $mmf->logconfess("loadHeader() failed to load '$mmf->{base}.hdr': $!");
  }
  elsif (defined($hdr)) {
    return $mmf->SUPER::loadHeaderData($hdr);
  }
  return $mmf;
}

## $bool = $enum->saveHeader()
##  + inherited from DiaColloDB::Persistent

##--------------------------------------------------------------
## I/O: text

## $bool = $obj->loadTextFile($filename_or_handle, %opts)
##  + wraps loadTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $mmf = $CLASS_OR_OBJECT->loadTextFh($fh)
##  + loads from text file with lines of the form "A B1 B2..."
##  + clobbers multimap contents
sub loadTextFh {
  my ($mmf,$fh,%opts) = @_;
  $mmf = $mmf->new(%opts) if (!ref($mmf));

  my $pack_b = $mmf->{pack_b};
  my @a2b  = qw();
  my ($a,@b);
  while (defined($_=<$fh>)) {
    chomp;
    next if (/^%%/ || /^$/);
    ($a,@b) = split(' ',$_);
    $a2b[$a] = pack($pack_b, @b);
  }

  ##-- clobber multimap
  return $mmf->fromArray(\@a2b);
}

## $bool = $obj->saveTextFile($filename_or_handle, %opts)
##  + wraps saveTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $mmf->saveTextFh($filename_or_fh,%opts)
##  + save from text file with lines of the form "A B1 B2..."
##  + %opts:
##     a2s=>\&a2s  ##-- stringification code for A items, called as $s=$a2s->($bi)
##     b2s=>\&b2s  ##-- stringification code for B items, called as $s=$b2s->($bi)
sub saveTextFh {
  my ($mmf,$fh,%opts) = @_;

  my $a2s    = $opts{a2s};
  my $b2s    = $opts{b2s};
  my $pack_b = $mmf->{pack_b};
  my $a2b    = $mmf->toArray;
  my $a      = 0;
  foreach (@$a2b) {
    if (defined($_)) {
      $fh->print(($a2s ? $a2s->($a) : $a),
		 "\t",
		 join(' ',
		      ($b2s
		       ? (map {$b2s->($_)} unpack($pack_b,$_))
		       : unpack($pack_b, $_))),
		 "\n");
    }
    ++$a;
  }

  return $mmf;
}


##==============================================================================
## Methods: population (in-memory only)

## $newsize = $mmf->addPairs($a,@bs)
## $newsize = $mmf->addPairs($a,\@bs)
##  + adds mappings $a=>$b foreach $b in @bs
##  + multimap must be loaded to memory
sub addPairs {
  my $mmf = shift;
  my $a   = shift;
  my $bs  = UNIVERSAL::isa($_[0],'ARRAY') ? $_[0] : \@_;
  $mmf->{a2b}[$a] .= pack($mmf->{pack_b}, @$bs);
  return $mmf->{size} = scalar(@{$mmf->{a2b}});
}

##==============================================================================
## Methods: lookup

## $bs_packed = $mmf->fetchraw($a)
##  + returns packed array \@bs of targets for $a, or undef if not found
sub fetchraw {
  my ($mmf,$a) = @_;
  return '' if (!defined($a));

  my ($boff,$blen,$buf);
  CORE::seek($mmf->{afh}, $a*$mmf->{len_a}, SEEK_SET)
      or $mmf->logconfess("fetch(): seek() failed on $mmf->{base}.ma for a=$a");
  CORE::read($mmf->{afh},$buf,$mmf->{len_a})==$mmf->{len_a}
      or $mmf->logconfess("fetch(): read() failed on $mmf->{base}.ma for a=$a");
  ($boff,$blen) = unpack($mmf->{pack_a}, $buf);

  $boff *= $mmf->{len_i};
  $blen *= $mmf->{len_i};
  CORE::seek($mmf->{bfh}, $boff, SEEK_SET)
      or $mmf->logconfess("fetch(): seek() failed on $mmf->{base}.mb to offset $boff for a=$a");
  CORE::read($mmf->{bfh}, $buf, $blen)==$blen
      or $mmf->logconfess("fetch(): read() failed on $mmf->{base}.mb for target-set of $blen byte(s) at offset $boff for a=$a");

  return $buf;
}

## \@bs_or_undef = $mmf->fetch($a)
##  + returns array \@bs of targets for $a, or undef if not found
##  + multimap must be opened
sub fetch {
  return [unpack($_[0]{pack_b}, $_[0]->fetchraw(@_[1..$#_]))];
}

##==============================================================================
## Footer
1;

__END__




