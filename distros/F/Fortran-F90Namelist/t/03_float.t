#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   03_float.t
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


## Scalar integers
$nl->parse("&nlist1\nx=7.34\ny=9e-12,z=-17.3\n/");
my $hashref1 =
  {
   'x' => {
	   'value' => [ '7.34' ],
	   'stype' => 'unspecified float', 'type' => 5
	  },
   'y' => {
	   'value' => [ '9e-12' ],
	   'stype' => 'single precision float', 'type' => 6
	  },
   'z' => {
	   'value' => [ '-17.3' ],
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
xx=7.1,8.2,9.3 ! array
  yy=-10.5,-5.0,0.0,5.1,10.9,! another array
zz=4*-12.9e-3
!The end
/");
my $hashref2 =
  {
   'xx' => {
	    'value' => [ '7.1', '8.2', '9.3' ],
	    'stype' => 'unspecified float', 'type' => 5
	   },
   'yy' => {
	    'value' => [ '-10.5', '-5.0', '0.0', '5.1', '10.9' ],
	    'stype' => 'unspecified float', 'type' => 5
	   },
   'zz' => {
	    'value' => [ '-12.9e-3', '-12.9e-3', '-12.9e-3', '-12.9e-3' ],
	    'stype' => 'single precision float', 'type' => 6
	   }
  };

# 5.
is(       $nl->name,   "nlist_2", "name");

# 6.
is(       $nl->nslots, 3,         "nslots");

# 7.
is_deeply($nl->hash,   $hashref2, "data");


# End of file 03_float.t
