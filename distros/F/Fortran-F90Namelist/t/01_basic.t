#!/usr/bin/perl -w

# Name:   01_basic.t
# Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
# Date:   05-Feb-2005
# Description:
#   Part of test suite for Namelist module

use strict;
use Test::More tests => 2;
#use Test::More qw(no_plan);

## Loading of module
BEGIN {
    use_ok('Fortran::F90Namelist');
}

## Object creation
my $nl = Fortran::F90Namelist->new();
isa_ok($nl, 'Fortran::F90Namelist');


# End of file 01_basic.t
