#!perl
use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Devel::CCompat::C99::ScopedVariables', ':all' );
}

is( Devel::CCompat::C99::ScopedVariables::create_scoped_variable(10),
    ((10)*(10-1))/2, 'expect 50');
