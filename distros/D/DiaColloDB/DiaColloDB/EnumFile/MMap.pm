## -*- Mode: CPerl -*-
## File: DiaColloDB::EnumFile::MMap.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, symbol<->integer enum, using mmap

package DiaColloDB::EnumFile::MMap;
use DiaColloDB::EnumFile;
use DiaColloDB::Utils qw(:fcntl :file :json :regex);
use File::Map qw(map_handle);
use Fcntl qw(:DEFAULT :seek);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::EnumFile);

##==============================================================================
## Constructors etc.

## $cldb = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- EnumFile: basic options
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
##    ##-- EnumFile: in-memory construction and caching
##    s2i => \%s2i,        ##-- maps symbols to integers
##    i2s => \@i2s,        ##-- maps integers to symbols
##    dirty => $bool,      ##-- true if in-memory structures are not in-sync with file data
##    loaded => $bool,     ##-- true if file data has been loaded to memory
##    shared => $bool,     ##-- true to avoid closing filehandles on close() or DESTROY() (default=false)
##    ##
##    ##-- EnumFile: pack lengths (after open())
##    len_i => $len_i,     ##-- bytes::length(pack($pack_i,0))
##    len_o => $len_o,     ##-- bytes::length(pack($pack_o,0))
##    len_l => $len_l,     ##-- bytes::length(pack($pack_l,0))
##    len_sx => $len_sx,   ##-- $len_o + $len_i
##    ##
##    ##-- EnumFile: filehandles (after open())
##    sfh  => $sfh,        ##-- $base.es  : pack("(${pack_l}/A)*", @$i2s)
##    ixfh => $ixfh,       ##-- $base.eix : [$i] => pack("${pack_o}",          $offset_in_sfh_of_string_with_id_i)
##    sxfh => $sxfh,       ##-- $base.esx : [$j] => pack("${pack_o}${pack_i}", $offset_in_sfh_of_string_with_sortindex_j_and_id_i, $i)
##    ##
##    ##-- EnumFile::MMap: buffers
##    sbufr  => \$sbuf,     ##-- mmap $base.es
##    ixbufr => \$ixbuf,    ##-- mmap $base.eix
##    sxbufr => \$sxbuf,    ##-- mmap $base.esx
##   )
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   #sbufr=>undef,
			   #ixbufr=>undef,
			   #sxbufr=>undef,
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
##  + opens file(s), clears {loaded} flag
sub open {
  my ($enum,$base,$flags) = @_;
  $enum->SUPER::open($base,$flags) or return undef;
  return $enum if (!$enum->isa(__PACKAGE__)); ##-- superclass open() promoted us to another class
  return $enum->remap();
}

## $enum_or_undef = $enum->remap()
##  + re-maps mmap buffers from enum handles
sub remap {
  my $enum = shift;

  ##-- mmap handles
  my $mapmode = fcperl($enum->{flags});
  map_handle(my $sbuf,  $enum->{sfh},  $mapmode);
  map_handle(my $ixbuf, $enum->{ixfh}, $mapmode);
  map_handle(my $sxbuf, $enum->{sxfh}, $mapmode);

  ##-- buffers
  $enum->{sbufr} = \$sbuf;
  $enum->{ixbufr} = \$ixbuf;
  $enum->{sxbufr} = \$sxbuf;

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
  delete @$enum{qw(sbufr ixbufr sxbufr)};
  return $enum->SUPER::close();
}

## $bool = $enum->opened()
sub opened {
  my $enum = shift;
  return
    (
     #defined($enum->{base}) &&
     defined($enum->{sbufr})
     && defined($enum->{ixbufr})
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

## $bool = $enum->loaded()
##  + returns true iff in-memory structures have been populated from disk
##  + INHERITED

## $bool = $enum->flush()
## $bool = $enum->flush($force)
##  + flush in-memory structures to disk
##  + no-op unless $force or $enum->dirty() is true
##  + clobbers any old disk-file contents with in-memory maps
##  + enum must be opened in write-mode
##  + INHERITED


##--------------------------------------------------------------
## I/O: memory <-> file

## \@i2s = $enum->toArray()
sub toArray {
  my $enum = shift;
  return $enum->{i2s}//[] if ($enum->loaded || !$enum->opened);
  my @i2s = unpack("($enum->{pack_l}/A)*", ${$enum->{sbufr}});
  push(@i2s, @{$enum->{i2s}}[scalar(@i2s)..$#{$enum->{i2s}}]) if ($enum->dirty && $enum->{i2s});
  return \@i2s;
}

## $enum = $enum->fromArray(\@i2s)
##  + clobbers $enum contents, steals \@i2s
##  + INHERITED

## $enum = $enum->fromEnum($enum2)
##  + clobbers $enum contents, does NOT steal $enum2->{i2s}
##  + INHERITED

## $bool = $enum->load()
##  + loads files to memory; must be opened
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
##   + in-memory cache overrides file contents
sub i2s {
  my ($enum,$i) = @_;
  return undef if ($i >= $enum->{size});

  my $buf;
  return $buf  if (defined($buf=$enum->{i2s}[$i]));

  my $soff = unpack($enum->{pack_o}, substr(${$enum->{ixbufr}}, $i*$enum->{len_o}, $enum->{len_o})) // return undef;
  my $slen = unpack($enum->{pack_l}, substr(${$enum->{sbufr}},  $soff, $enum->{len_l}));
  $buf     = substr(${$enum->{sbufr}}, $soff+$enum->{len_l}, $slen);
  utf8::decode($buf) if ($enum->{utf8});
  return $buf;
}

## $i_or_undef = $enum->s2i($s)
## $i_or_undef = $enum->s2i($s, $ilo,$ihi)
##   + binary search; enum must be opened
sub s2i {
  my ($enum,$key,$ilo,$ihi) = @_;

  my ($sxbufr,$sbufr,$len_sx,$pack_o,$len_o,$pack_l,$len_l) = @$enum{qw(sxbufr sbufr len_sx pack_o len_o pack_l len_l)};
  $ilo //= 0;
  $ihi //= $enum->{dirty} ? (length($$sxbufr)/$len_sx) : $enum->{size};

  my ($imid,$buf,$soff,$slen,$si);
  return $buf if (defined($buf=$enum->{s2i}{$key}));

  utf8::encode($key) if ($enum->{utf8} && utf8::is_utf8($key));
  while ($ilo < $ihi) {
    $imid = ($ihi+$ilo) >> 1;

    ##-- get sx-record @ $imid
    $soff = unpack($pack_o, substr($$sxbufr, $imid*$len_sx, $len_o));

    ##-- get string for sx-record
    $slen = unpack($pack_l, substr($$sbufr, $soff, $len_l));
    $buf  = substr($$sbufr, $soff+$len_l, $slen);

    if ($buf lt $key) {
      $ilo = $imid + 1;
    } else {
      $ihi = $imid;
    }
  }

  ##-- output
  if ($ilo==$ihi) {
    ##-- get sx-record @ $ilo
    ($soff,$si) = unpack($enum->{pack_o}.$enum->{pack_i}, substr($$sxbufr, $ilo*$len_sx, $len_sx));
    return undef if (!defined($soff));

    ##-- get string for sx-record
    $slen = unpack($pack_l, substr($$sbufr, $soff, $len_l));
    $buf  = substr($$sbufr, $soff+$len_l, $slen);

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

  ##-- iteration a la toArray()
  my $pack_l = $enum->{pack_l};
  my $len_l  = $enum->{len_l};
  my $sbufr  = $enum->{sbufr};
  my $offmax = length($$sbufr);
  my @is     = qw();
  my ($off,$i,$len_s,$s);
  for ($i=$off=0; $off < $offmax; ++$i, $off += ($len_l+$len_s)) {
    $len_s = unpack($pack_l, substr($$sbufr, $off, $len_l));
    $s     = substr($$sbufr, $off+$len_l, $len_s);
    utf8::decode($s) if ($utf8);
    push(@is, $i) if ($s =~ $re);
  }

  push(@is, grep {utf8::decode($_) if ($utf8); $i2s->[$_] =~ $re} (((-s $enum->{ixfh})/$enum->{len_o})..$#{$enum->{i2s}})) if ($enum->dirty);
  return \@is;
}

##==============================================================================
## Footer
1;

__END__
