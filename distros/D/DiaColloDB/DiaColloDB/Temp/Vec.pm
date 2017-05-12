## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Temp::Vec.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DiaColloDB utilities: (temporary) mmaped vec() buffers

package DiaColloDB::Temp::Vec;
use DiaColloDB::Temp;
use File::Map;
use File::Temp;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Temp);
our $LOG_DEFAULT = undef;	##-- default log-level (undef: off)

##==============================================================================
## Constructors etc.

## $tmpvec = CLASS->new($size, $bits, %opts)
##  + %opts, %$tmpvec:
##    (
##     log  => $level,      ##-- logging verbosity (default=$LOG_DEFAULT)
##     buf  => $buf,        ##-- guts: real underlying mmap()ed buffer data
##     size => $size,       ##-- number of logical elements
##     bits => $bits,       ##-- number of bits per element
##    )
sub new {
  my $that = UNIVERSAL::isa($_[0],__PACKAGE__) ? shift : __PACKAGE__;
  my $size = shift;
  my $bits = shift;
  my %opts = @_;
  $that->logconfess("Usage: ", __PACKAGE__, "::new(SIZE, BITS)") if (!defined($size) || !defined($bits));
  my $log    = $opts{log} // $LOG_DEFAULT;

  ##-- guts
  $that->vlog($log, "CREATE (anonymous): $size elements, $bits bits/element (TEMP)");
  my $tmpv = bless({
		    %opts,
		   }, ref($that)||$that);
  my $bufr = \$tmpv->{buf};
  File::Map::map_anonymous($$bufr, $size*$bits, 'shared');
  $that->logconfess("new(): map_anonymous failed for ", ($size*$bits), " byte(s): $!") if (!defined($$bufr));
  return $tmpv;
}

##==============================================================================
## Accessors

## \$buf = $tmpv->bufr()
sub bufr {
  return undef if (!UNIVERSAL::isa($_[0],'HASH'));
  return \$_[0]{buf};
}

## $bits = $tmpv->bits()
sub bits { return $_[0]{bits}; }

## $size = $tmpv->size()
sub size { return $_[0]{size}; }

##==============================================================================
## Footer
1; ##-- be happy
