#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTTP::Response::Encoding' );
}

diag( "Testing HTTP::Response::Encoding $HTTP::Response::Encoding::VERSION, Perl $], $^X" );
