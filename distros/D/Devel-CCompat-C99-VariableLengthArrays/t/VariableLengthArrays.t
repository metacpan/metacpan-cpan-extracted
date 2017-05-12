#!perl
use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Devel::CCompat::C99::VariableLengthArrays', ':all' );
}

is( Devel::CCompat::C99::VariableLengthArrays::create_array(10),
    11, 'expect (10)+1' );
