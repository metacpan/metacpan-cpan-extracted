### -*- Mode: CPerl -*-
## File: DiaColloDB::EnumFile::FixedMap.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, symbol<->integer enum, fixed-length symbols, mmaped

package DiaColloDB::EnumFile::FixedMap;
use DiaColloDB::EnumFile::FixedLen;
use DiaColloDB::Utils qw(:fcntl :file :json :regex :pack);
use File::Map qw(map_handle);
use Fcntl qw(:DEFAULT :seek);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::EnumFile::FixedLen);

##==============================================================================
## Constructors etc.

## $cldb = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- EnumFile: basic options
##    base => $base,       ##-- database basename; use files "${base}.fsx", "${base}.fix", "${base}.hdr"
##    perms => $perms,     ##-- default: 0666 & ~umask
##    flags => $flags,     ##-- default: 'r'
##    pack_i => $pack_i,   ##-- integer pack template (default='N')
##    #pack_o => $pack_o,   ##-- file offset pack template (default='N') ; OVERRIDE/FixedLen: unused
##    #pack_l => $pack_l,   ##-- string-length pack template (default='n'); OVERRIDE/FixedLen: unused
##    pack_s => $pack_s,   ##-- string pack template for text i/o; OVERRIDE:REQUIRED (default='Nn')
##    size => $size,       ##-- number of mapped symbols, like scalar(@i2s)
##    ##
##    ##-- EnumFile: in-memory construction
##    s2i => \%s2i,        ##-- maps symbols to integers
##    i2s => \@i2s,        ##-- maps integers to symbols
##    dirty => $bool,      ##-- true if in-memory structures are not in-sync with file data
##    loaded => $bool,     ##-- true if file data has been loaded to memory
##    ##
##    ##-- EnumFile: pack lengths (after open())
##    len_i => $len_i,     ##-- packsize($pack_i)
##    #len_o => $len_o,     ##-- packsize($pack_o) ; OVERRIDE/FixedLen: unused
##    #len_l => $len_l,     ##-- packsize($pack_l) ; OVERRIDE/FixedLen: unused
##    len_s => $len_s,     ##-- packsize($pack_s); OVERRIDE/FixedLen: new
##    len_sx => $len_sx,   ##-- $len_s + $len_i ; OVERRIDE/FixedLen: new value
##    ##
##    ##-- EnumFile: filehandles (after open())
##    #sfh  => $sfh,        ##-- $base.s  : OVERRIDE/FixedLen: unused
##    ixfh => $ixfh,       ##-- $base.fix : [$i] => pack("${pack_s}",          $s_with_id_i) : OVERRIDE/FixedLen: new extension, format
##    sxfh => $sxfh,       ##-- $base.fsx : [$j] => pack("${pack_s}${pack_i}", $s_with_sortorder_j_and_id_i, $i) : OVERRIDE/FixedLen: new extension, format
##    ##
##    ##-- FixedMap: buffers
##    #sbufr  => \$sbuf,     ##-- mmap $base.s  # OVERRIDE/FixedMap: unused
##    ixbufr => \$ixbuf,    ##-- mmap $base.fix  # OVERRIDE/FixedMap: new format
##    sxbufr => \$sxbuf,    ##-- mmap $base.fsx  # OVERRIDE/FixedMap: new format
##   )
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   @_, ##-- user arguments
			  );
}

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: open/close (file)

## $enum_or_undef = $enum->open($base,$flags)
## $enum_or_undef = $enum->open($base)
## $enum_or_undef = $enum->open()
sub open {
  my ($enum,$base,$flags) = @_;
  $enum->SUPER::open($base,$flags) or return undef;
  return $enum->remap();
}

## $enum_or_undef = $enum->remap()
##  + re-maps mmap buffers from enum handles
sub remap {
  my $enum = shift;

  ##-- mmap handles
  my $mapmode = fcperl($enum->{flags});
  map_handle(my $ixbuf, $enum->{ixfh}, $mapmode);
  map_handle(my $sxbuf, $enum->{sxfh}, $mapmode);

  ##-- buffers
  $enum->{ixbufr} = \$ixbuf;
  $enum->{sxbufr} = \$sxbuf;

  ##-- flags
  $enum->{loaded} = 0;

  return $enum;
}

## $enum_or_undef = $enum->close()
##  + INHERITED

## $bool = $enum->opened()
sub opened {
  my $enum = shift;
  return
    (
     #defined($enum->{base}) &&
     #defined($enum->{sbufr}) &&
     defined($enum->{ixbufr})
     && defined($enum->{sxbufr})
    );
}

## $bool = $enum->reopen()
##  + re-opens datafiles
##  + override also remaps buffers
sub reopen {
  my $enum = shift;
  return $enum->SUPER::reopen() && $enum->remap();
}


## $bool = $enum->dirty()
##  + returns true iff some in-memory structures haven't been flushed to disk
##  + INHERITED

## $bool = $enum->flush()
##  + flush in-memory structures to disk
##  + clobbers any old disk-file contents with in-memory maps
##  + enum must be opened in write-mode
##  + invalidates any old references to {s2i}, {i2s} (but doesn't empty them if you need to keep a reference)
##  + INHERITED

##--------------------------------------------------------------
## I/O: memory <-> file

## \@i2s = $enum->toArray()
sub toArray {
  my $enum = shift;
  return $enum->{i2s} if ($enum->loaded || !$enum->opened);

  ##-- bizarre bug Mon, 03 Aug 2015 15:46:27 +0200 on plato
  ##  + getting 9-byte items in this array for 10-byte (4+4+2) records
  ##  + i2s() works as expected
  ##  + wtf?!
  #my @i2s = unpack("(A[$enum->{len_s}])*", ${$enum->{ixbufr}});
  my $len_s = $enum->{len_s};
  my @i2s   = map {substr(${$enum->{ixbufr}},$_*$len_s,$len_s)} (0..($enum->size-1));

  push(@i2s, @{$enum->{i2s}}[scalar(@i2s)..$#{$enum->{i2s}}]) if ($enum->dirty);
  return \@i2s;
}

## $enum = $enum->fromArray(\@i2s)
##  + clobbers $enum contents, steals \@i2s
##  + INHERITED

## $enum = $enum->fromHash(\%s2i)
##  + clobbers $enum contents, steals \%s2i
##  + INERHITED

## $enum = $enum->fromEnum($enum2)
##  + clobbers $enum contents, does NOT steal $enum2->{i2s}
##  + INHERITED

## $bool = $enum->load()
##  + loads files to memory; must be opened
##  + INHERITED

## $enum = $enum->save()
## $enum = $enum->save($base)
##  + saves enum to $base; really just a wrapper for open() and flush()
##  + INHERITED

##--------------------------------------------------------------
## I/O: header
##  + INHERITED

##--------------------------------------------------------------
## I/O: text
##  + INHERITED

##==============================================================================
## Methods: population (in-memory only)
##  + INHERITED

##==============================================================================
## Methods: lookup

## $s_or_undef = $enum->i2s($i)
##  + enum must be opened
sub i2s {
  #my ($enum,$i) = @_;
  return undef if ($_[1] >= $_[0]{size});
#  return $s  if (defined(my $s=$_[0]{i2s}[$_[1]]));
  return substr(${$_[0]{ixbufr}}, $_[1]*$_[0]{len_s}, $_[0]{len_s});
}

## $i_or_undef = $enum->s2i($s)
## $i_or_undef = $enum->s2i($s, $ilo,$ihi)
##   + binary search; enum must be opened
sub s2i {
  my ($enum,$key,$ilo,$ihi) = @_;

  my ($sxbufr,$len_s,$len_sx) = @$enum{qw(sxbufr len_s len_sx)};
  $ilo //= 0;
  $ihi //= $enum->{dirty} ? (length($$sxbufr)/$len_sx) : $enum->{size};

  my ($imid,$s,$si);
#  return $s if (defined($s=$enum->{s2i}{$key}));

  while ($ilo < $ihi) {
    $imid = ($ihi+$ilo) >> 1;

    ##-- check sx-record @ $imid
    if (substr($$sxbufr, $imid*$len_sx, $len_s) lt $key) {
      $ilo = $imid + 1;
    } else {
      $ihi = $imid;
    }
  }

  ##-- output
  if ($ilo==$ihi) {
    ##-- get sx-record @ $ilo
    ($s,$si) = unpack("A[$len_s]$enum->{pack_i}", substr($$sxbufr, $ilo*$len_sx, $len_sx));
    return $si if ($s eq $key);
  }

  return undef;
}


## \@is = $enum->re2i($regex, $pack_s)
##  + gets indices for all (packed) strings matching $regex
##  + if $pack_s is specified, is will be used to unpack strings (default=$enum->{pack_s}), only the first unpacked element will be tested
sub re2i {
  my ($enum,$re,$pack_s) = @_;
  $re = regex($re) if (!ref($re));

  $pack_s //= $enum->{pack_s};
  my $i2s   = $enum->{i2s};

  if ($enum->loaded || !$enum->opened) {
    ##-- easy answer: loaded
    if ($pack_s) {
      my ($s);
      return [grep {($s)=unpack($pack_s,$i2s->[$_]); $s =~ $re} [0..$#$i2s]];
    } else {
      return [grep {$i2s->[$_] =~ $re} [0..$#$i2s]];
    }
  }

  ##-- iteration a la toArray
  my $ixbufr = $enum->{ixbufr};
  my $len_s  = $enum->{len_s};
  my $offmax = length($$ixbufr);
  my @is     = qw();
  my ($off,$i,$buf);
  for ($off=$i=0; $off < $offmax; $off += $len_s, ++$i) {
    $buf   = substr($$ixbufr, $off, $len_s);
    ($buf) = unpack($pack_s,$buf) if ($pack_s);
    push(@is, $i) if ($buf =~ $re);
  }

  ##-- append expansions from in-memory cache
  if ($enum->dirty) {
    if ($pack_s) {
      my ($s);
      push(@is, grep {($s)=unpack($pack_s,$i2s->[$_]); $s =~ $re} (((-s $enum->{ixfh})/$enum->{len_s})..$#$i2s));
    } else {
      push(@is, grep {$i2s->[$_] =~ $re} (((-s $enum->{ixfh})/$len_s)..$#$i2s));
    }
  }
  return \@is;
}

##==============================================================================
## alias: DiaColloDB::EnumFile::FixedLen::MMap
package DiaColloDB::EnumFile::FixedLen::MMap;
our @ISA = qw(DiaColloDB::EnumFile::FixedMap);

##==============================================================================
## Footer
1;

__END__




