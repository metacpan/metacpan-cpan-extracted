#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Debug::Simple' );
}

diag( "Testing Debug::Simple $Debug::Simple::VERSION, Perl $], $^X" );
