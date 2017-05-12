## -*- Mode: CPerl -*-
## File: DiaColloDB::Compat::v0_08::MultiMapFile
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, integer->integer* multimap file, e.g. for expansion indices (v0.08.x format)

package DiaColloDB::Compat::v0_08::MultiMapFile;
use DiaColloDB::MultiMapFile;
use DiaColloDB::Compat;
use DiaColloDB::Logger;
use DiaColloDB::Persistent;
use DiaColloDB::Utils qw(:fcntl :json :pack);
use Fcntl qw(:DEFAULT :seek);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::MultiMapFile DiaColloDB::Compat);

##==============================================================================
## Constructors etc.

## $cldb = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    base => $base,       ##-- database basename; use files "${base}.ma", "${base}.mb", "${base}.hdr"
##    perms => $perms,     ##-- default: 0666 & ~umask
##    flags => $flags,     ##-- default: 'r'
##    pack_i => $pack_i,   ##-- integer pack template (default='N')
##    pack_o => $pack_o,   ##-- file offset pack template (default='N')
##    pack_l => $pack_l,   ##-- set-length pack template (default='N')
##    size => $size,       ##-- number of mapped , like scalar(@data)
##    ##
##    ##-- in-memory construction
##    a2b => \@a2b,        ##-- maps source integers to (packed) target integer-sets: [$a] => pack("${pack_i}*", @bs)
##    ##
##    ##-- computed pack-templates and -lengths (after open())
##    pack_a => $pack_a,   ##-- "${pack_i}"
##    pack_b => $pack_a,   ##-- "${pack_i}*"
##    len_i => $len_i,     ##-- bytes::length(pack($pack_i,0))
##    len_o => $len_o,     ##-- bytes::length(pack($pack_o,0))
##    len_l => $len_l,     ##-- bytes::length(pack($pack_l,0))
##    ##
##    ##-- filehandles (after open())
##    afh => $afh,         ##-- $base.ma : [$a]      => pack(${pack_o}, $boff_a)
##    bfh => $bfh,         ##-- $base.mb : $boff_a   :  pack("${pack_l}/(${pack_i}*)",  @targets_for_a)
##   )
sub new {
  my $that = shift;
  my $mmf  = bless({
		     base => undef,
		     perms => (0666 & ~umask),
		     flags => 'r',
		     size => 0,
		     pack_i => 'N',
		     pack_o => 'N',
		     pack_l => 'N',

		     a2b=>[],

		     #len_i => undef,
		     #len_o => undef,
		     #len_l => undef,
		     #len_a => undef,
		     #pack_a => undef,
		     #pack_b => undef,

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
  if (fcread($flags) && !fctrunc($flags)) {
    $mmf->loadHeader()
      or $mmf->logconess("failed to load header from '$mmf->{base}.hdr': $!");
  }

  $mmf->{afh} = fcopen("$base.ma", $flags, $mmf->{perms})
    or $mmf->logconfess("open failed for $base.ma: $!");
  $mmf->{bfh} = fcopen("$base.mb", $flags, $mmf->{perms})
    or $mmf->logconfess("open failed for $base.mb: $!");
  binmode($_,':raw') foreach (@$mmf{qw(afh bfh)});

  ##-- computed pack lengths & templates
  $mmf->{pack_o} //= $mmf->{pack_i};
  $mmf->{pack_l} //= $mmf->{pack_i};
  $mmf->{pack_a} = $mmf->{pack_i};
  $mmf->{pack_b} = $mmf->{pack_i}."*";
  $mmf->{len_i} = packsize($mmf->{pack_i});
  $mmf->{len_o} = packsize($mmf->{pack_o});
  $mmf->{len_l} = packsize($mmf->{pack_l});
  $mmf->{len_a} = $mmf->{len_o} + $mmf->{len_l};

  return $mmf;
}

## $mmf_or_undef = $mmf->close()
##  + INHERITED from MultiMapFile

## $bool = $mmf->opened()
##  + INHERITED from MultiMapFile

## $bool = $mmf->dirty()
##  + returns true iff some in-memory structures haven't been flushed to disk
##  + INHERITED from MultiMapFile

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
  my ($a2b,$pack_o,$pack_l,$len_l,$pack_i,$len_i) = @$mmf{qw(a2b pack_o pack_l len_l pack_i len_i)};
  my $off   = 0;
  my $ai    = 0;
  my $bsz;
  foreach (@$a2b) {
    $_ //= '';
    $bsz = length($_);
    $afh->print(pack($pack_o, $off))
      or $mmf->logconfess("flush(): failed to write source record for a=$ai to $mmf->{base}.ma");
    $bfh->print(pack($pack_l, $bsz/$len_i), $_)
      or $mmf->logconfess("flush(): failed to write targets for a=$ai to $mmf->{base}.mb");
    $off += $len_l + $bsz;
    ++$ai;
  }

  ##-- truncate datafiles at current position
  CORE::truncate($afh, $afh->tell());
  CORE::truncate($bfh, $bfh->tell());

  ##-- clear in-memory structures (but don't clobber existing references)
  $mmf->{a2b} = [];

  return $mmf;
}


##--------------------------------------------------------------
## I/O: memory <-> file

## \@a2b = $mmf->toArray()
sub toArray {
  my $mmf = shift;
  return $mmf->{a2b} if (!$mmf->opened);

  #use bytes; ##-- deprecated in perl v5.18.2
  my ($pack_l,$len_l,$pack_i,$len_i) = @$mmf{qw(pack_l len_l pack_i len_i)};
  my $bfh    = $mmf->{bfh};
  my @a2b    = qw();
  my ($buf,$bsz);
  for (CORE::seek($bfh,0,SEEK_SET); !eof($bfh); ) {
    CORE::read($bfh, $buf, $len_l)==$len_l
	or $mmf->logconfess("toArray(): read() failed on $mmf->{base}.mb for target-set size at offset ", tell($bfh), ", item ", scalar(@a2b));
    $bsz = $len_i * unpack($pack_l, $buf);

    CORE::read($bfh, $buf, $bsz)==$bsz
	or $mmf->logconfess("toArray(): read() failed on $mmf->{base}.mb for target-set of $bsz bytes at offset ", tell($bfh), ", item ", scalar(@a2b));
    push(@a2b, $buf);
  }
  push(@a2b, @{$mmf->{a2b}}[scalar(@a2b)..$#{$mmf->{a2b}}]) if ($mmf->dirty);
  return \@a2b;
}

## $mmf = $mmf->fromArray(\@a2b)
##  + clobbers $mmf contents, steals \@a2b
##  + INHERITED from MultiMapFile

## $bool = $mmf->load()
##  + loads files to memory; must be opened
##  + INHERITED from MultiMapFile

## $mmf = $mmf->save()
## $mmf = $mmf->save($base)
##  + saves multimap to $base; really just a wrapper for open() and flush()
##  + INHERITED from MultiMapFile

##--------------------------------------------------------------
## I/O: header
##  + see also DiaColloDB::Persistent

## @keys = $coldb->headerKeys()
##  + keys to save as header
##  + INHERITED from MultiMapFile

## $bool = $CLASS_OR_OBJECT->loadHeader()
##  + wraps $CLASS_OR_OBJECT->loadHeaderFile($CLASS_OR_OBJ->headerFile())
##  + INHERITED from DiaColloDB::Persistent

## $bool = $mmf->loadHeaderData($hdr)
##  + INHERITED from MultiMapFile

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
##  + INHERITED from MultiMapFile

## $bool = $obj->saveTextFile($filename_or_handle, %opts)
##  + wraps saveTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $mmf->saveTextFh($filename_or_fh,%opts)
##  + save from text file with lines of the form "A B1 B2..."
##  + %opts:
##     a2s=>\&a2s  ##-- stringification code for A items, called as $s=$a2s->($bi)
##     b2s=>\&b2s  ##-- stringification code for B items, called as $s=$b2s->($bi)
##  + INHERITED from MultiMapFile

##==============================================================================
## Methods: population (in-memory only)

## $newsize = $mmf->addPairs($a,@bs)
## $newsize = $mmf->addPairs($a,\@bs)
##  + adds mappings $a=>$b foreach $b in @bs
##  + multimap must be loaded to memory
##  + INHERITED from MultiMapFile

##==============================================================================
## Methods: lookup

## $bs_packed = $mmf->fetchraw($a)
sub fetchraw {
  my ($mmf,$a) = @_;
  return '' if (!defined($a));

  my ($boff,$bsz,$buf);
  CORE::seek($mmf->{afh}, $a*$mmf->{len_o}, SEEK_SET)
      or $mmf->logconfess("fetch(): seek() failed on $mmf->{base}.ma for a=$a");
  CORE::read($mmf->{afh},$buf,$mmf->{len_o})==$mmf->{len_o}
      or $mmf->logconfess("fetch(): read() failed on $mmf->{base}.ma for a=$a");
  $boff = unpack($mmf->{pack_o},$buf);

  CORE::seek($mmf->{bfh}, $boff, SEEK_SET)
      or $mmf->logconfess("fetch(): seek() failed on $mmf->{base}.mb to offset $boff for a=$a");
  CORE::read($mmf->{bfh}, $buf,$mmf->{len_l})==$mmf->{len_l}
      or $mmf->logconfess("fetch(): read() failed on $mmf->{base}.mb for target-set length at offset $boff for a=$a");
  $bsz = $mmf->{len_i} * unpack($mmf->{pack_l},$buf);

  CORE::read($mmf->{bfh}, $buf, $bsz)==$bsz
      or $mmf->logconfess("fetch(): read() failed on $mmf->{base}.mb for target-set of size $bsz bytes at offset $boff for a=$a");

  return $buf;
}

## \@bs_or_undef = $mmf->fetch($a)
##  + returns array \@bs of targets for $a, or undef if not found
##  + multimap must be opened
##  + INHERITED from MultiMapFile

##==============================================================================
## Footer
1;

__END__




