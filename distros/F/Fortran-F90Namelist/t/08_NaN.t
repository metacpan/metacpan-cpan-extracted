#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   08_NaN.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   12-May-2005
# Description:
#   Part of test suite for Namelist module

use strict;
use Test::More tests => 7;
use Fortran::F90Namelist;

# 1.
my $nl = Fortran::F90Namelist->new();
isa_ok($nl, 'Fortran::F90Namelist');

## Scalar logicals
$nl->parse(<<"HERE");
  &nlist1
    x = NaN,
    y = Inf,
    z = -Inf
  /
HERE

my $hashref1 =
  {
   'x' => {
	   'value' => [ 'NaN' ],
	   'stype' => 'unspecified float', 'type' => 5
	  },
   'y' => {
	   'value' => [ 'Inf' ],
	   'stype' => 'unspecified float', 'type' => 5
	  },
   'z' => {
	   'value' => [ '-Inf' ],
	   'stype' => 'unspecified float', 'type' => 5
	  }
  };

# 2.
is(       $nl->name,   "nlist1", "name");

# 3.
is(       $nl->nslots, 3,        "nslots");

# 4.
is_deeply($nl->hash,   $hashref1, "data");


## Integer arrays, multiplier syntax, interspersed comments
$nl->parse("
!test namelist
&nlist_2
xx=3,5.39,NaN ! array
  yy=2.D0,Inf! another array
zz=2*Inf,3*NaN
!The end
/");
my $hashref2 =
  {
   'xx' => {
	    'value' => [ '3', '5.39', 'NaN' ],
	   'stype' => 'unspecified float',      'type' => 5
	   },
   'yy' => {
	    'value' => [ '2.D0', 'Inf' ],
	   'stype' => 'double precision float', 'type' => 7
	   },
   'zz' => {
	    'value' => [ 'Inf', 'Inf', 'NaN', 'NaN', 'NaN' ],
	   'stype' => 'unspecified float',      'type' => 5
	   }
  };

# 5.
is(       $nl->name,   "nlist_2", "name");

# 6.
is(       $nl->nslots, 3,         "nslots");

# 7.
is_deeply($nl->hash,   $hashref2, "data");


# End of file 08_NaN.t
