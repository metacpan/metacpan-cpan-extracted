#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Graphics::Primitive::Driver::CairoPango' );
}

diag( "Testing Graphics::Primitive::Driver::CairoPango $Graphics::Primitive::Driver::CairoPango::VERSION, Perl $], $^X" );
