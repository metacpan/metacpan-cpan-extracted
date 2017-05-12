#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   05_complex.t
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
$nl->parse("&nlist1\nz1=(7.34,5.98)\nz2=(9,5)\n/");
my $hashref1 =
  {
   'z1' => {
	    'value' => [ '(7.34,5.98)' ],
	    'stype' => 'complex number', 'type' => 8
	   },
   'z2' => {
	    'value' => [ '(9,5)' ],
	    'stype' => 'complex number', 'type' => 8
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
zz1= (7.1,0),(8.2,1),(-8.2,-1) ! array
  zz2 =4*(-12.9,5)
!The end
/");
my $hashref2 =
  {
   'zz1' => {
	    'value' => [ '(7.1,0)', '(8.2,1)', '(-8.2,-1)' ],
	    'stype' => 'complex number', 'type' => 8
	   },
   'zz2' => {
	    'value' => [ '(-12.9,5)', '(-12.9,5)', '(-12.9,5)', '(-12.9,5)' ],
	    'stype' => 'complex number', 'type' => 8
	   }
  };

# 5.
is(       $nl->name,   "nlist_2", "name");

# 6.
is(       $nl->nslots, 2,         "nslots");

# 7.
is_deeply($nl->hash,   $hashref2, "data");


# End of file 05_complex.t
