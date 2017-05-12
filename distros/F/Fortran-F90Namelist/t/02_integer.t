#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   02_integer.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   06-Feb-2005
# Description:
#   Part of test suite for Namelist module

use strict;
use Test::More tests => 7;
use Fortran::F90Namelist;

# 1.
my $nl = Fortran::F90Namelist->new();
isa_ok($nl, 'Fortran::F90Namelist');


## Scalar integers
$nl->parse("&nlist1\nl=7\nm=9,n=-17\n/");
my $hashref1 =
  {
   'l' => {
	   'value' => [ '7' ],
	   'stype' => 'integer', 'type' => 4
	  },
   'm' => {
	   'value' => [ '9' ],
	   'stype' => 'integer', 'type' => 4
	  },
   'n' => {
	   'value' => [ '-17' ],
	   'stype' => 'integer', 'type' => 4
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
ll=7,8,9 ! array
  mm=-10,-5,0,5,10,! another array
nn=4*-12
!The end
/");
my $hashref2 =
  {
   'll' => {
	    'value' => [ '7', '8', '9' ],
	    'stype' => 'integer', 'type' => 4
	   },
   'mm' => {
	    'value' => [ '-10', '-5', '0', '5', '10' ],
	    'stype' => 'integer', 'type' => 4
	   },
   'nn' => {
	    'value' => [ '-12', '-12', '-12', '-12' ],
	    'stype' => 'integer', 'type' => 4
	   }
  };

# 5.
is(       $nl->name,   "nlist_2", "name");

# 6.
is(       $nl->nslots, 3,         "nslots");

# 7.
is_deeply($nl->hash,   $hashref2, "data");


# End of file 02_integer.t
