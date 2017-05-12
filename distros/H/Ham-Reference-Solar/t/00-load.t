#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Ham::Reference::Solar' );
}

diag( "Testing Ham::Reference::Solar $Ham::Reference::Solar::VERSION, Perl $], $^X" );
