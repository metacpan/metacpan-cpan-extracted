#!perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;

use_ok( 'Math::BaseArith', qw(:all));

#########################

is "2"         , join(' ',decode_base( [0, 0, 1, 0],    [2, 2, 2, 2]    )), 'vec[4], vec[4] base 2';
is "5"         , join(' ',decode_base( [0, 1, 0, 1],    [2, 2, 2, 2]    )), 'vec[4], vec[4] base 2';
is "62"        , join(' ',decode_base( [0, 3, 14],      [16, 16, 16]    )), 'vec[3], vec[4] base 16';
is "15"        , join(' ',decode_base( [1, 1, 1, 1],    [2, 2, 2, 2]    )), 'vec[4], vec[4] base 2';
is "15"        , join(' ',decode_base( [1, 1, 1, 1],    [2]             )), 'vec[4], vec[1] base 2';
# In APL, the following test yields 15 if the [1] is passed as a scalar (but not if a vector)
is "1"         , join(' ',decode_base( [1],             [2, 2, 2, 2]    )), 'vec[1], vec[4] base 2';
is "175"       , join(' ',decode_base( [4, 2, 7],       [0, 3, 12]      )), 'yd+ft+in to in';
is "183927"    , join(' ',decode_base( [2, 3, 5, 27],   [0, 24, 60, 60] )), 'hr+min+sec to sec';
is "3065.45"   , join(' ',decode_base( [2, 3, 5, 27],   [0, 24, 60, 60] )) / 60, 'hr+min+sec to min';

diag q(Ignore the following 'length error' message);
my $retval;
eval { $retval = decode_base( [1, 1, 1, 1], [2, 2, 2] ) };
ok !$retval, 'length error test ';

