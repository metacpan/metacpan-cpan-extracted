#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   06_double_complex.t
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
$nl->parse("&nlist1\nz1=(7.34D0,5.98D1)\nz2=(9D+2,5D-3)\n/");
my $hashref1 =
  {
   'z1' => {
	    'value' => [ '(7.34D0,5.98D1)' ],
	    'stype' => 'double precision complex number', 'type' => 9
	   },
   'z2' => {
	    'value' => [ '(9D+2,5D-3)' ],
	    'stype' => 'double precision complex number', 'type' => 9
	   }
  };

# 2.
is(       $nl->name,   "nlist1", "name");

# 3.
is(       $nl->nslots, 2,        "nslots");

# 4.
is_deeply($nl->hash,   $hashref1, "data");


## Integer arrays, multiplier syntax, interspersed comments
$nl->parse("
!test namelist
&nlist_2
zz1= (7.1D0,0D-2),(8.2D+3,1D3),(-8.2D-3,-1D-3) ! array
  zz2 =3*(-12.D3,5D+2)
!The end
/");
my $hashref2 =
  {
   'zz1' => {
	     'value' => [ '(7.1D0,0D-2)', '(8.2D+3,1D3)', '(-8.2D-3,-1D-3)' ],
	     'stype' => 'double precision complex number', 'type' => 9
	    },
   'zz2' => {
	     'value' => [ '(-12.D3,5D+2)', '(-12.D3,5D+2)', '(-12.D3,5D+2)' ],
	     'stype' => 'double precision complex number', 'type' => 9
	    }
  };

# 5.
is(       $nl->name,   "nlist_2", "name");

# 6.
is(       $nl->nslots, 2,         "nslots");

# 7.
is_deeply($nl->hash,   $hashref2, "data");


# End of file 06_double_complex.t
