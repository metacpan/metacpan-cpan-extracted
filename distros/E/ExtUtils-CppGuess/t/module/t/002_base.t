use strict;
use Test::More tests => 2;

use CppGuessTest;

is( CppGuessTest::silly_test( 4 ), 9 );
is( CppGuessTest::useless_test( "foo", "bar" ), "foobar" );
