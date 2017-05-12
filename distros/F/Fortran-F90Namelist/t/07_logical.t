#!/usr/bin/perl -w
# -*-mode:cperl-*-

# Name:   07_logical.t
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
$nl->parse("&nlist1\nl=T\nm=.false.,n=.TRUE.\n/");
my $hashref1 =
  {
   'l' => {
	   'value' => [ 'T' ],
	   'stype' => 'logical', 'type' => 3
	  },
   'm' => {
	   'value' => [ '.false.' ],
	   'stype' => 'logical', 'type' => 3
	  },
   'n' => {
	   'value' => [ '.TRUE.' ],
	   'stype' => 'logical', 'type' => 3
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
ll=.true.,.FALSE.,F ! array
  mm=F,T,T,F! another array
nn=2*T,3*F,2*.true.
!The end
/");
my $hashref2 =
  {
   'll' => {
	    'value' => [ '.true.', '.FALSE.', 'F' ],
	    'stype' => 'logical', 'type' => 3
	   },
   'mm' => {
	    'value' => [ 'F', 'T', 'T', 'F' ],
	    'stype' => 'logical', 'type' => 3
	   },
   'nn' => {
	    'value' => [ 'T', 'T', 'F', 'F', 'F', '.true.', '.true.' ],
	    'stype' => 'logical', 'type' => 3
	   }
  };

# 5.
is(       $nl->name,   "nlist_2", "name");

# 6.
is(       $nl->nslots, 3,         "nslots");

# 7.
is_deeply($nl->hash,   $hashref2, "data");


# End of file 07_logical.t
