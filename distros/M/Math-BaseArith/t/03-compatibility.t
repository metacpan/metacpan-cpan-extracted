#!perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

use_ok( 'Math::BaseArith' );

#########################

is "0 0 1 0"   , join(' ',encode( 2,   [2, 2, 2, 2] ) ), 'encode imported by default';
is "2"         , join(' ',decode( [0, 0, 1, 0],    [2, 2, 2, 2]    )), 'decode imported by default';
