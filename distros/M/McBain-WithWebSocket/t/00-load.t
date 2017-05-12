#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'McBain::WithWebSocket' ) || print "Bail out!\n";
}

diag( "Testing McBain::WithWebSocket $McBain::WithWebSocket::VERSION, Perl $], $^X" );
