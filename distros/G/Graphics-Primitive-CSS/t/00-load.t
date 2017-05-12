#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Graphics::Primitive::CSS' );
}

diag( "Testing Graphics::Primitive::CSS $Graphics::Primitive::CSS::VERSION, Perl $], $^X" );
