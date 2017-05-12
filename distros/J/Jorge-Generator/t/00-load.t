#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Jorge::Generator' );
	use_ok( 'Jorge::Generator::Controller' );
	use_ok( 'Jorge::Generator::Model' );
}

diag( "Testing Jorge::Generator $Jorge::Generator::VERSION, Perl $], $^X" );
