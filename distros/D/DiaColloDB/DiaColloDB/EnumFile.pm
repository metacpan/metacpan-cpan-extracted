## -*- Mode: CPerl -*-
## File: DiaColloDB::EnumFile.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, symbol<->integer enum

package DiaColloDB::EnumFile;
use DiaColloDB::Persistent;
use DiaColloDB::Utils qw(:fcntl :file :pack :json :regex);
use Fcntl qw(:DEFAULT :seek);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Persistent);

##==============================================================================
## Constructors etc.

## $cldb = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    base => $base,       ##-- database basename; use files "${base}.es", "${base}.esx", "${base}.eix", "${base}.hdr"
##    perms => $perms,     ##-- default: 0666 & ~umask
##    flags => $flags,     ##-- default: 'r'
##    pack_i => $pack_i,   ##-- integer pack template (default='N')
##    pack_o => $pack_o,   ##-- file offset pack template (default='N')
##    pack_l => $pack_l,   ##-- string-length pack template (default='n')
##    pack_s => $pack_s,   ##-- string pack template (default=undef) for text i/o
##    size => $size,       ##-- number of mapped symbols, like scalar(@i2s)
##    utf8 => $bool,       ##-- true iff strings are stored as utf8 (default, used by re2i())
##    ##
##    ##-- in-memory construction and caching
##    s2i => \%s2i,        ##-- maps symbols to integers
##    i2s => \@i2s,        ##-- maps integers to symbols
##    dirty => $bool,      ##-- true if in-memory structures are not in-sync with file data
##    loaded => $bool,     ##-- true if file data has been loaded to memory
##    shared => $bool,     ##-- true to avoid closing filehandles on close() or DESTROY() (default=false)
##    ##
##    ##-- pack lengths (after open())
##    len_i => $len_i,     ##-- packsize($pack_i)
##    len_o => $len_o,     ##-- packsize($pack_o)
##    len_l => $len_l,     ##-- packsize($pack_l)
##    len_sx => $len_sx,   ##-- $len_o + $len_i
##    ##
##    ##-- filehandles (after open())
##    sfh  => $sfh,        ##-- $base.es  : pack("(${pack_l}/A)*", @$i2s)
##    ixfh => $ixfh,       ##-- $base.eix : [$i] => pack("${pack_o}",          $offset_in_sfh_of_string_with_id_i)
##    sxfh => $sxfh,       ##-- $base.esx : [$j] => pack("${pack_o}${pack_i}", $offset_in_sfh_of_string_with_sortindex_j_and_id_i, $i)
##   )
sub new {
  my $that = shift;
  my $enum  = bless({
		     base => undef,
		     perms => (0666 & ~umask),
		     flags => 'r',
		     utf8 => 1,
		     size => 0,
		     pack_i => 'N',
		     pack_o => 'N',
		     pack_l => 'n',
		     pack_s => undef,

		     s2i => {},
		     i2s => [],
		     dirty=>0,
		     loaded=>0,

		     #len_i => undef,
		     #len_o => undef,
		     #len_l => undef,
		     #len_sx => undef,

		     #sfh  =>undef,
		     #ixfh =>undef,
		     #sxfh =>undef,

		     @_, ##-- user arguments
		    },
		    ref($that)||$that);
  $enum->{class} = ref($enum);
  $enum->{s2i} //= {};
  $enum->{i2s} //= [];
  return defined($enum->{base}) ? $enum->open($enum->{base}) : $enum;
}

sub DESTROY {
  $_[0]->close() if ($_[0]->opened);
}

## $enum = $enum->promote($class,$force)
##  + promote to $class
##  + if $force is false (default), promotion to CLASS::MMap will be disabled
sub promote {
  my ($enum,$class,$force) = @_;
  return $enum if (UNIVERSAL::isa($enum,$class)
		   || (!$force && UNIVERSAL::isa((ref($enum)||$enum)."::MMap", $class)));
  return $class->new() if (!ref($enum));
  %$enum = ((UNIVERSAL::can($class,'new') ? %{$class->new} : qw()),%$enum);
  return bless($enum,$class);
}

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: open/close (file)

## $enum_or_undef = $enum->open($base,$flags)
## $enum_or_undef = $enum->open($base)
## $enum_or_undef = $enum->open()
##  + opens file(s), clears {loaded} flag
sub open {
  my ($enum,$base,$flags) = @_;
  $base  //= $enum->{base};
  $flags //= $enum->{flags};
  $enum->close() if ($enum->opened);
  $enum->{base}  = $base;
  $enum->{flags} = $flags = fcflags($flags);
  if (fcread($flags) && !fctrunc($flags)) {
    $enum->loadHeader()
      or $enum->logconess("failed to load header from '$enum->{base}.hdr': $!");
    return $enum->promote($enum->{hclass})->open($base,$flags)
      if ($enum->{hclass} && !$enum->isa($enum->{hclass})); ##-- auto-promote based on header data
  }

  $enum->{sfh} = fcopen("$base.es", $flags, $enum->{perms})
    or $enum->logconfess("open failed for $base.es: $!");
  $enum->{ixfh} = fcopen("$base.eix", $flags, $enum->{perms})
    or $enum->logconfess("open failed for $base.eix: $!");
  $enum->{sxfh} = fcopen("$base.esx", $flags, $enum->{perms})
    or $enum->logconfess("open failed for $base.esx: $!");
  binmode($_,':raw') foreach (@$enum{qw(sfh ixfh sxfh)});

  ##-- pack lengths
  #use bytes; ##-- deprecated in perl v5.18.2
  $enum->{len_i} = packsize($enum->{pack_i});
  $enum->{len_o} = packsize($enum->{pack_o});
  $enum->{len_l} = packsize($enum->{pack_l});
  $enum->{len_sx} = $enum->{len_o} + $enum->{len_i};

  ##-- flags
  $enum->{loaded} = 0;

  return $enum;
}

## $enum_or_undef = $enum->close()
sub close {
  my $enum = shift;
  if ($enum->opened && fcwrite($enum->{flags})) {
    $enum->flush() or return undef;
  }
  if (!$enum->{shared}) {
    !defined($enum->{sxfh}) or $enum->{sxfh}->close() or return undef;
    !defined($enum->{ixfh}) or $enum->{ixfh}->close() or return undef;
    !defined($enum->{sfh})  or $enum->{sfh}->close() or return undef;
  }
  delete @$enum{qw(sxfh ixfh sfh)};
  $enum->{s2i} //= {};
  $enum->{i2s} //= [];
  undef $enum->{base};
  return $enum;
}

## $bool = $enum->opened()
sub opened {
  my $enum = shift;
  return
    (
     #defined($enum->{base}) &&
     defined($enum->{sfh})
     && defined($enum->{ixfh})
     && defined($enum->{sxfh})
    );
}

## $bool = $enum->reopen()
##  + re-opens datafiles
sub reopen {
  my $enum = shift;
  my $base = $enum->{base} || "$enum";
  return (
	  $enum->opened
	  && fh_reopen($enum->{sfh}, "$base.es")
	  && fh_reopen($enum->{ixfh}, "$base.eix")
	  && fh_reopen($enum->{sxfh}, "$base.esx")
	 );
}

## $bool = $enum->dirty()
##  + returns true iff some in-memory structures haven't been flushed to disk
sub dirty {
  return $_[0]{dirty}; #@{$_[0]{i2s}} || %{$_[0]{s2i}};
}

## $bool = $enum->loaded()
##  + returns true iff in-memory structures have been populated from disk
sub loaded {
  return $_[0]{loaded};
}

## $bool = $enum->rollback()
##  + drops in-memory structures
##  + invalidates any old references to {s2i}, {i2s} (but doesn't empty them if you need to keep a reference)
##  + clears {dirty} flag
sub rollback {
  my $enum = shift;
  $enum->{i2s} = [];
  $enum->{s2i} = {};
  $enum->{dirty} = 0;
  return $enum;
}

## $bool = $enum->flush()
## $bool = $enum->flush($force)
##  + flush in-memory structures to disk
##  + no-op unless $force or $enum->dirty() is true
##  + clobbers any old disk-file contents with in-memory maps
##  + enum must be opened in write-mode
##  + invalidates any old references to {s2i}, {i2s} (but doesn't empty them if you need to keep a reference)
##  + clears {dirty} flag
sub flush {
  my ($enum,$force) = @_;
  return undef if (!$enum->opened || !fcwrite($enum->{flags}));
  return $enum if (!$force && !$enum->dirty);

  ##-- save header
  $enum->saveHeader()
    or $enum->logconfess("flush(): failed to store header $enum->{base}.hdr: $!");

  #use bytes; ##-- deprecated in perl v5.18.2
  my ($sfh,$ixfh,$sxfh) = @$enum{qw(sfh ixfh sxfh)};
  $sfh->seek(0,SEEK_SET);
  $ixfh->seek(0,SEEK_SET);
  $sxfh->seek(0,SEEK_SET);

  ##-- dump $base.es, $base.eix
  #no warnings 'uninitialized';
  my $i2s    = $enum->{i2s};
  my $utf8   = $enum->{utf8};
  my ($pack_o,$pack_l,$len_l) = @$enum{qw(pack_o pack_l len_l)};
  my $i2off = []; ##-- >[$i] => $offset
  my $off   = 0;
  my $i     = 0;
  my ($s);
  foreach (@$i2s) {
    $s = ($_ //= '');
    utf8::encode($s) if ($utf8 && utf8::is_utf8($s));
    $sfh->print(pack("${pack_l}/A", $s))
      or $enum->logconfess("flush(): failed to write string '$s' at offset $off to $enum->{base}.es");
    $ixfh->print(pack($pack_o,$off))
      or $enum->logconfess("flush(): failed to write ix-record for id=$i to $enum->{base}.eix");
    push(@$i2off, $off);
    $off += $len_l + length($s);
    ++$i;
  }
  CORE::truncate($sfh, $sfh->tell());
  CORE::truncate($ixfh, $ixfh->tell());

  ##-- dump $base.esx
  my $pack_sx = $enum->{pack_o}.$enum->{pack_i};
  foreach $i (sort {$i2s->[$a] cmp $i2s->[$b]} (0..$#$i2s)) {
    $sxfh->print(pack($pack_sx, $i2off->[$i], $i))
      or $enum->logconfess("flush(): failed to dump sx-record for id $i to $enum->{base}.esx");
  }
  CORE::truncate($sxfh, $sxfh->tell());

  ##-- clear in-memory structures (but don't clobber existing references; used for xenum by DiaColloDB::create())
  $enum->rollback();
  $enum->reopen() or return undef if ((caller(1))[3] !~ /::close$/);
  return $enum;
}


##--------------------------------------------------------------
## I/O: memory <-> file

## \@i2s = $enum->toArray()
##  + array items are still encoded
sub toArray {
  my $enum = shift;
  return $enum->{i2s} if ($enum->loaded || !$enum->opened);
  #use bytes; ##-- deprecated in perl v5.18.2
  my $pack_l = $enum->{pack_l};
  my $len_l  = $enum->{len_l};
  my $sfh    = $enum->{sfh};
  my @i2s    = qw();
  my ($buf,$len_s);
  for (CORE::seek($sfh,0,SEEK_SET); !eof($sfh); ) {
    CORE::read($sfh, $buf, $len_l)==$len_l
	or $enum->logconfess("toArray(): read() failed on $enum->{base}.es for string length at offset ", tell($sfh));
    $len_s = unpack($pack_l, $buf);

    CORE::read($sfh, $buf, $len_s)==$len_s
	or $enum->logconfess("toArray(): read() failed on $enum->{base}.es for string of length $len_s at offset ", tell($sfh));
    push(@i2s, $buf);
  }
  push(@i2s, @{$enum->{i2s}}[scalar(@i2s)..$#{$enum->{i2s}}]) if ($enum->dirty);
  return \@i2s;
}

## $enum = $enum->fromArray(\@i2s)
##  + clobbers $enum contents, steals \@i2s
sub fromArray {
  my ($enum,$i2s) = @_;
  $enum->{i2s} = $i2s;
  my $i = 0;
  foreach (@$i2s) {
    next if (!defined($_));
    $enum->{s2i}{$_} = $i++;
  }
  $enum->{size} = scalar(@{$enum->{i2s}});
  $enum->{dirty} = 1;
  return $enum;
}

## $enum = $enum->fromHash(\%s2i)
##  + clobbers $enum contents, steals \%s2i
sub fromHash {
  my ($enum,$s2i) = @_;
  $enum->{s2i} = $s2i;
  @{$enum->{i2s}}[values %$s2i] = keys %$s2i;
  $enum->{size} = scalar(@{$enum->{i2s}});
  $enum->{dirty} = 1;
  return $enum;
}


## $enum = $enum->fromEnum($enum2)
##  + clobbers $enum contents, does NOT steal $enum2->{i2s}
sub fromEnum {
  my ($enum,$e2) = @_;
  if ($e2->opened && !$e2->loaded) {
    ##-- file->mem
    return $enum->fromArray($e2->toArray);
  } else {
    ##-- mem->mem
    @{$enum->{i2s}} = @{$e2->{i2s}};
    %{$enum->{s2i}} = %{$e2->{s2i}};
    $enum->{dirty} = 1;
  }
  return $enum;
}

## $bool = $enum->load()
##  + loads files to memory; must be opened
sub load {
  my $enum = shift;
  my $dirty = $enum->{dirty};
  $enum->fromArray($enum->toArray) or return undef;
  $enum->{loaded} = 1;
  $enum->{dirty}  = $dirty;
  return $enum;
}

## $enum = $enum->save()
## $enum = $enum->save($base)
##  + saves enum to $base; really just a wrapper for open() and flush()
sub save {
  my ($enum,$base) = @_;
  $enum->open($base,'rw') if (defined($base));
  $enum->logconfess("save(): cannot save un-opened enum") if (!$enum->opened);
  $enum->flush() or $enum->logconfess("save(): failed to flush to $enum->{base}: $!");
  return $enum;
}


##--------------------------------------------------------------
## I/O: header
##  + see also DiaColloDB::Persistent

## @keys = $coldb->headerKeys()
##  + keys to save as header
sub headerKeys {
  return grep {!ref($_[0]{$_}) && $_ !~ m{^(?:flags|perms|base|loaded|dirty|hclass)$}} keys %{$_[0]};
}

## $bool = $enum->loadHeaderData($hdr)
##  + instantiates header data from $hdr
##  + overrides DiaColloDB::Persistent implementation
sub loadHeaderData {
  my ($enum,$hdr) = @_;
  if (!defined($hdr) && !fccreat($enum->{flags})) {
    $enum->logconfess("loadHeaderData() failed to load header data from ", $enum->headerFile, ": $!");
  }
  elsif (defined($hdr)) {
    $enum->{hclass} = $hdr->{class};  ##-- save stored header-class
    $enum->SUPER::loadHeaderData($hdr);
  }
  return $enum;
}

## $bool = $enum->saveHeader()
##  + inherited from DiaColloDB::Persistent

##--------------------------------------------------------------
## I/O: text
##  + largely INHERITED from DiaColloDB::Persistent

## $bool = $obj->loadTextFile($filename_or_handle, %opts)
##  + wraps loadTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $enum = $CLASS_OR_OBJECT->loadTextFh($fh)
## $enum = $CLASS_OR_OBJECT->loadTextFh($fh, %opts)
##  + loads from text file with lines of the form "ID SYMBOL..."
##  + clobbers enum contents
##  + %opts locally clobber %$enum, especially:
##     pack_s => $pack_s
sub loadTextFh {
  my ($enum,$fh,%opts) = @_;
  $enum = $enum->new(%opts) if (!ref($enum));
  my $pack_s  = exists($opts{pack_s}) ? $opts{pack_s} : $enum->{pack_s};
  my $packsub = $pack_s && !UNIVERSAL::isa($pack_s,'CODE') ? sub { pack($pack_s,split(/\t/,$_[0])) } : $pack_s;
  my @i2s  = qw();
  my ($i,$s);
  while (defined($_=<$fh>)) {
    chomp;
    next if (/^%%/ || /^$/);
    ($i,$s) = split(/\s/,$_,2);
    $s = $packsub->($s) if ($packsub);
    $i2s[$i] = $s;
  }

  ##-- clobber enum
  return $enum->fromArray(\@i2s);
}

## $bool = $obj->saveTextFile($filename_or_fh, %opts)
##  + wraps saveTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $enum->saveTextFh($fh,%opts)
##  + save from text file with lines of the form "ID SYMBOL..."
##  + %opts locally clobber %$enum, especially:
##     pack_s => $pack_s
sub saveTextFh {
  my ($enum,$fh,%opts) = @_;
  my $pack_s  = exists($opts{pack_s}) ? $opts{pack_s} : $enum->{pack_s};
  my $packsub = $pack_s && !UNIVERSAL::isa($pack_s,'CODE') ? sub { join("\t", unpack($pack_s,$_[0])) } : $pack_s;
  my $i2s    = $enum->toArray;
  my $i      = 0;
  foreach (@$i2s) {
    if (defined($_)) {
      $fh->print($i, "\t", ($packsub ? $packsub->($_) : $_), "\n");
    }
    ++$i;
  }
  return $enum;
}


##==============================================================================
## Methods: population (in-memory only)

## $size = $enum->size()
##  + wraps {size} key
sub size { return $_[0]{size}; }

## $newsize = $enum->setsize($newsize)
##  + realy just wraps {size} key
sub setsize { return $_[0]{size}=$_[1]; }

## $newsize = $enum->addSymbols(@symbols)
## $newsize = $enum->addSymbols(\@symbols)
##  + adds all symbols in @symbols which don't already exist
##  + enum must be loaded to memory
sub addSymbols {
  my $enum    = shift;
  my $symbols = UNIVERSAL::isa($_[0],'ARRAY') ? $_[0] : \@_;
  my $n   = $enum->{size};
  my $s2i = $enum->{s2i};
  my $i2s = $enum->{i2s};
  foreach (@$symbols) {
    next if (exists $s2i->{$_});
    $s2i->{$_} = $n;
    $i2s->[$n] = $_;
    ++$n;
  }
  $enum->{dirty} = 1;
  return $enum->{size}=$n;
}

## $newsize = $enum->appendSymbols(@symbols)
## $newsize = $enum->appendSymbols(\@symbols)
##  + adds all symbols in @symbols in order, messily re-mapping them if they already exist
sub appendSymbols {
  my $enum    = shift;
  my $symbols = UNIVERSAL::isa($_[0],'ARRAY') ? $_[0] : \@_;
  my $n   = $enum->{size};
  my $s2i = $enum->{s2i};
  my $i2s = $enum->{i2s};
  foreach (@$symbols) {
    $s2i->{$_} = $n;
    $i2s->[$n] = $_;
    ++$n;
  }
  $enum->{dirty} = 1;
  return $enum->{size}=$n;
}

## $newsize = $enum->addEnum($enum2_or_undef)
##  + ensures all symbols from $enum2_or_undef are defined (undef:'')
sub addEnum {
  my ($e1,$e2) = @_;
  return $e1->addSymbols(defined($e2) ? $e2->toArray : '');
}

##==============================================================================
## Methods: lookup

## $s_or_undef = $enum->i2s($i)
##   + in-memory cache overrides file contents
sub i2s {
  my ($enum,$i) = @_;
  return undef if ($i >= $enum->{size});
  my ($buf,$soff,$slen);
  return $buf if (defined($buf=$enum->{i2s}[$i]));

  CORE::seek($enum->{ixfh}, $i*$enum->{len_o}, SEEK_SET)
      or $enum->logconfess("i2s(): seek() failed on $enum->{base}.eix for i=$i");
  CORE::read($enum->{ixfh},$buf,$enum->{len_o})==$enum->{len_o}
      or $enum->logconfess("i2s(): read() failed on $enum->{base}.eix for i=$i");
  $soff = unpack($enum->{pack_o},$buf);

  CORE::seek($enum->{sfh}, $soff, SEEK_SET)
      or $enum->logconfess("i2s(): seek() failed on $enum->{base}.es for offset $soff");
  CORE::read($enum->{sfh}, $buf,$enum->{len_l})==$enum->{len_l}
      or $enum->logconfess("i2s(): read() failed on $enum->{base}.es for string length at offset $soff");
  $slen = unpack($enum->{pack_l},$buf);

  CORE::read($enum->{sfh}, $buf, $slen)==$slen
      or $enum->logconfess("i2s(): read() failed on $enum->{base}.es for string of length $slen at offset $soff");

  utf8::decode($buf) if ($enum->{utf8});
  return $buf;
}

## $i_or_undef = $enum->s2i($s)
## $i_or_undef = $enum->s2i($s, $ilo,$ihi)
##   + binary search; in-memory cache overrides file contents
sub s2i {
  my ($enum,$key,$ilo,$ihi) = @_;

  my ($sxfh,$sfh,$len_sx,$pack_o,$len_o,$pack_l,$len_l) = @$enum{qw(sxfh sfh len_sx pack_o len_o pack_l len_l)};
  $ilo //= 0;
  $ihi //= $enum->{dirty} ? ((-s $sxfh)/$len_sx) : $enum->{size};

  my ($imid,$buf,$soff,$slen,$si);
  return $buf if (defined($buf=$enum->{s2i}{$key}));

  utf8::encode($key) if ($enum->{utf8} && utf8::is_utf8($key));
  while ($ilo < $ihi) {
    $imid = ($ihi+$ilo) >> 1;

    ##-- get sx-record @ $imid
    CORE::seek($sxfh, $imid*$len_sx, SEEK_SET)
	or $enum->logconfess("s2i(): seek() failed on $enum->{base}.esx for item $imid");
    CORE::read($sxfh, $buf, $len_o)==$len_o
	or $enum->logconfess("s2i(): read() failed on $enum->{base}.esx for item $imid");
    $soff = unpack($pack_o, $buf);

    ##-- get string for sx-record
    CORE::seek($sfh, $soff, SEEK_SET)
	or $enum->logconfess("s2i(): seek() failed on $enum->{base}.es for offset $soff");
    CORE::read($sfh, $buf, $len_l)==$len_l
	or $enum->logconfess("s2i(): read() failed on $enum->{base}.es for string length at offset $soff");
    $slen = unpack($pack_l, $buf);
    CORE::read($sfh, $buf, $slen)==$slen
	or $enum->logconfess("s2i(): read() failed on $enum->{base}.es for string of length $slen at offset $soff");

    if ($buf lt $key) {
      $ilo = $imid + 1;
    } else {
      $ihi = $imid;
    }
  }

  ##-- output
  if ($ilo==$ihi) {
    ##-- get sx-record @ $ilo
    CORE::seek($sxfh, $ilo*$len_sx, SEEK_SET)
	or $enum->logconfess("s2i(): seek() failed on $enum->{base}.esx for item $ilo");
    return undef if ($sxfh->eof);
    CORE::read($sxfh, $buf, $len_sx)==$len_sx
	or $enum->logconfess("s2i(): read() failed on $enum->{base}.esx for item $ilo");
    ($soff,$si) = unpack($enum->{pack_o}.$enum->{pack_i}, $buf);

    ##-- get string for sx-record
    CORE::seek($sfh, $soff, SEEK_SET)
	or $enum->logconfess("s2i(): seek() failed on $enum->{base}.es for offset $soff");
    CORE::read($sfh, $buf, $len_l)==$len_l
	or $enum->logconfess("s2i(): read() failed on $enum->{base}.es for string length at offset $soff");
    $slen = unpack($pack_l, $buf);
    CORE::read($sfh, $buf, $slen)==$slen
	or $enum->logconfess("s2i(): read() failed on $enum->{base}.es for string of length $slen at offset $soff");

    return $si if ($buf eq $key);
  }

  return undef;
}

## \@is = $enum->re2i($regex)
##  + gets indices for all strings matching $regex
sub re2i {
  my ($enum,$re) = @_;
  my $utf8 = $enum->{utf8};

  if (!ref($re)) {
    utf8::decode($re) if ($utf8 && !utf8::is_utf8($re));
    $re = regex($re);
  }

  my $i2s  = $enum->{i2s};
  if ($enum->loaded || !$enum->opened) {
    ##-- easy answer: loaded
    return [grep {utf8::decode($_) if ($utf8); $i2s->[$_] =~ $re} (0..$#$i2s)];
  }

  ##-- iteration a la toArray
  #use bytes; ##-- deprecated in perl v5.18.2
  my $pack_l = $enum->{pack_l};
  my $len_l  = $enum->{len_l};
  my $sfh    = $enum->{sfh};
  my @is     = qw();
  my $i      = 0;
  my ($buf,$len_s);
  for ($i=0, CORE::seek($sfh,0,SEEK_SET); !eof($sfh); ++$i) {
    CORE::read($sfh, $buf, $len_l)==$len_l
	or $enum->logconfess("re2i(): read() failed on $enum->{base}.es for string length at offset ", tell($sfh));
    $len_s = unpack($pack_l, $buf);

    CORE::read($sfh, $buf, $len_s)==$len_s
	or $enum->logconfess("re2i(): read() failed on $enum->{base}.es for string of length $len_s at offset ", tell($sfh));

    utf8::decode($buf) if ($utf8);
    push(@is, $i) if ($buf =~ $re);
  }

  push(@is, grep {utf8::decode($_) if ($utf8); $i2s->[$_] =~ $re} (((-s $enum->{ixfh})/$enum->{len_o})..$#{$enum->{i2s}})) if ($enum->dirty);
  return \@is;
}


##==============================================================================
## Footer
1;

__END__
