#!perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 17;

use_ok( 'Math::BaseArith', qw( :all ) );

#########################

is "0 0 1 0"   , join(' ',encode_base( 2,   [2, 2, 2, 2] ) ), 'scalar, vec[4] base 2';
is "0 1 0 1"   , join(' ',encode_base( 5,   [2, 2, 2, 2] ) ), 'scalar, vec[4] base 2';
is "1 1 0 1"   , join(' ',encode_base( 13,  [2, 2, 2, 2] ) ), 'scalar, vec[4] base 2';
is "0 3 14"    , join(' ',encode_base( 62,  [16, 16, 16] ) ), 'scalar, vec[4] base 16';
is "1 0 2 3"   , join(' ',encode_base( 75,  [4, 4, 4, 4] ) ), 'scalar, vec[4] base 4';
is "0 2 3"     , join(' ',encode_base( 75,  [4, 4, 4]    ) ), 'scalar, vec[3] base 4';
is "2 3"       , join(' ',encode_base( 75,  [4, 4]       ) ), 'scalar, vec[2] base 4';
is "3"         , join(' ',encode_base( 75,  [4]          ) ), 'scalar, vec[1] base 4';
is "0"         , join(' ',encode_base( 76,  [4]          ) ), 'scalar, vec[1] base 4';
is "75"        , join(' ',encode_base( 75,  [0]          ) ), 'scalar, vec[1] no base';
is "18 3"      , join(' ',encode_base( 75,  [0, 4]       ) ), 'scalar, vec[2] base 4';
is "4 2 3"     , join(' ',encode_base( 75,  [0, 4, 4]    ) ), 'scalar, vec[3] base 4';
is "1 0 2 3"   , join(' ',encode_base( 75,  [0, 4, 4, 4] ) ), 'scalar, vec[4] base 4';
is "14 7"      , join(' ',encode_base( 175, [0, 12]      ) ), 'inches to ft';
is "4 2"       , join(' ',encode_base( 14,  [0, 3]       ) ), 'ft to yds';
is "4 2 7"     , join(' ',encode_base( 175, [0, 3, 12]   ) ), 'inches to ft+in';

