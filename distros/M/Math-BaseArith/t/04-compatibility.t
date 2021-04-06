#!perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;

use_ok( 'Math::BaseArith', qw( :all !:old ) );

is "0 0 1 0"   , join(' ',encode_base( 2,   [2, 2, 2, 2] ) ), 'encode_base imported with :all`';
is "2"         , join(' ',decode_base( [0, 0, 1, 0],    [2, 2, 2, 2]    )), 'decode_base imported with :all';

eval { 
    encode( 2, [2, 2, 2, 2] ) 
};

like $@, qr{Undefined \s subroutine \s &main::encode }xms, 'encode not exported with !:old';

eval { 
    decode( [0, 0, 1, 0], [2, 2, 2, 2] ) 
};

like $@, qr{Undefined \s subroutine \s &main::decode }xms, 'decode not exported with !:old';
