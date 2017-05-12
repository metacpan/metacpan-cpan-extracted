#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Graphics::Primitive' );
}

diag( "Testing Graphics::Primitive $Graphics::Primitive::VERSION, Perl $], $^X" );
