#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Email::Public' );
}

diag( "Testing Email::Public $Email::Public::VERSION, Perl $], $^X" );
