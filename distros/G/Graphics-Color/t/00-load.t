#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Graphics::Color' );
}

diag( "Testing Graphics::Color $Graphics::Color::VERSION, Perl $], $^X" );
