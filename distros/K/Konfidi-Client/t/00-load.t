#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Konfidi::Client' );
}

diag( "Testing Konfidi::Client $Konfidi::Client::VERSION, Perl $], $^X" );
