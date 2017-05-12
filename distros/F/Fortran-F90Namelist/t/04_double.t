#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   04_double.t
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
$nl->parse("&nlist1\nx=7.34D0\ny=9d-12,z=-.173D1\n/");
my $hashref1 =
  {
   'x' => {
	   'value' => [ '7.34D0' ],
	   'stype' => 'double precision float', 'type' => 7
	  },
   'y' => {
	   'value' => [ '9d-12' ],
	   'stype' => 'double precision float', 'type' => 7
	  },
   'z' => {
	   'value' => [ '-.173D1' ],
	   'stype' => 'double precision float', 'type' => 7
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
xx=7.1D0,.82D1,93D-1 ! array
  yy=-10.5D0,-5.0D0,0.0D0,510D-2,1.09D+1,! another array
zz=4*-12.9D-3
!The end
/");
my $hashref2 =
  {
   'xx' => {
	    'value' => [ '7.1D0', '.82D1', '93D-1' ],
	    'stype' => 'double precision float', 'type' => 7
	   },
   'yy' => {
	    'value' => [ '-10.5D0', '-5.0D0', '0.0D0', '510D-2', '1.09D+1' ],
	    'stype' => 'double precision float', 'type' => 7
	   },
   'zz' => {
	    'value' => [ '-12.9D-3', '-12.9D-3', '-12.9D-3', '-12.9D-3' ],
	    'stype' => 'double precision float', 'type' => 7
	   }
  };

# 5.
is(       $nl->name,   "nlist_2", "name");

# 6.
is(       $nl->nslots, 3,         "nslots");

# 7.
is_deeply($nl->hash,   $hashref2, "data");


# End of file 04_double.t
