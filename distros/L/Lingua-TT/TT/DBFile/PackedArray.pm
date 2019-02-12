## -*- Mode: CPerl -*-
## File: Lingua::TT::DBFile::PackedArray.pm
## Author: Bryan Jurish <TT/IO.pm>
## Descript: TT I/O: Berkely DB: tied files: arrays (using DB_RECNO)


package Lingua::TT::DBFile::PackedArray;
use Lingua::TT::DBFile;
use DB_File;
use Carp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(Lingua::TT::DBFile);

##==============================================================================
## Constructors etc.

## $dbf = CLASS_OR_OBJECT->new(%opts)
## + %opts, %$doc:
##   ##-- overrides
##   packfmt => $fmt,      ##-- pack format (constant width); default='L'
##   type    => $type,     ##-- one of 'HASH', 'BTREE', 'RECNO' (default: 'RECNO')
##   dbinfo  => \%dbinfo,  ##-- default: "DB_File::RECNOINFO"->new();
##                         ##   + overrides 'flags', 'reclen'
##   ##
##   ##-- user options
##   file  => $directory,  ##-- default: undef (none)
##   mode  => $mode,       ##-- default: 0644
##   flags => $flags,      ##-- default: O_RDWR|O_CREAT
##   #type    => $type,     ##-- one of 'HASH', 'BTREE', 'RECNO' (default: 'RECNO')
##   dbopts  => \%opts,    ##-- db options (e.g. cachesize,bval,...) -- defaults to none (uses DB_File defaults)
##   ##
##   ##-- low-level data
##   packlen => $len,      ##-- length data
##   data   => $thingy,    ##-- tied data (hash or array)
##   tied   => $ref,       ##-- reference returned by tie()
sub new {
  my ($that,%opts) = @_;
  my $dbf = $that->SUPER::new(type=>'RECNO',packfmt=>'L',%opts,file=>undef);
  $dbf->{packlen} = length(pack($dbf->{packfmt})) if (!defined($dbf->{packlen}));
  $dbf->{dbinfo}{reclen} = $dbf->{packlen};
  $dbf->{dbinfo}{flags}  = R_FIXEDLEN;
  $dbf->{dbinfo}{bval}   = chr(0);
  return $dbf->open($opts{file}) if (defined($opts{file}));
  return $dbf;
}


##==============================================================================
## Access

## $packed = $pa->pack(@values)
sub pack {
  return CORE::pack($_[0]{packfmt},@_[1..$#_]);
}

## @values = $pa->unpack($packed)
sub unpack {
  return CORE::unpack($_[0]{packfmt},$_[1]);
}

##----------------------------------------------------------------------
## Access: Wrappers: p*

## $status = $pa->pput($key,@values)
sub pput ($@) {
  return $_[0]{tied}->put($_[1], CORE::pack($_[0]{packfmt},@_[2..$#_]));
}

## $status = $pa->pget($key,@values)
sub pget ($\@) {
  my ($rc,$val);
  $rc = $_[0]{tied}->get($_[1], $val);
  @{$_[1]} = CORE::unpack($_[0]{packfmt},$val);
  return $rc;
}

## @values = $pa->ppop();
sub ppop ($) {
  return CORE::unpack($_[0]{packfmt},$_[0]{tied}->pop);
}

## @values = $pa->pshift();
sub pshift ($) {
  return CORE::unpack($_[0]{packfmt},$_[0]{tied}->shift);
}

## undef = $pa->ppush(@values);
sub ppush ($@) {
  return $_[0]{tied}->push(CORE::pack($_[0]{packfmt},@_[1..$#_]));
}

## undef = $pa->punshift(@values);
sub punshift ($) {
  return $_[0]{tied}->unshift(CORE::pack($_[0]{packfmt},@_[1..$#_]));
}

##----------------------------------------------------------------------
## Access: Wrappers: r*

## $packed_values = $pa->rput($key,\@values)
sub rput ($$) {
  return $_[0]{data}[$_[1]] = CORE::pack($_[0]{packfmt},@{$_[1]});
}

## \@values = $pa->rget($key);
sub rget ($) {
  return [CORE::unpack($_[0]{packfmt},$_[0]{data}[$_[1]])];
}

## undef = $pa->rpush(\@vals1, ...);
sub rpush ($@) {
  return $_[0]{tied}->push(map {CORE::pack($_[0]{packfmt},@$_)} @_[1..$#_]);
}

## undef = $pa->runshift(\@vals1, ...);
sub runshift ($@) {
  return $_[0]{tied}->unshift(map {CORE::pack($_[0]{packfmt},@$_)} @_[1..$#_]);
}

##----------------------------------------------------------------------
## Access: Wrappers: a*

## $packed_values = $pa->aput($key,@values)
sub aput ($@) {
  return $_[0]{data}[$_[1]] = CORE::pack($_[0]{packfmt},@_[2..$#_]);
}

## @values = $pa->rget($key);
sub aget ($) {
  return CORE::unpack($_[0]{packfmt},$_[0]{data}[$_[1]]);
}

## undef = $pa->apush(@values);
## undef = $pa->aunshift(@values);
BEGIN {
  *apush = \&ppush;
  *aunshift = \&punshift;
}

##==============================================================================
## Footer
1;

__END__
