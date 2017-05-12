#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FreeMED::Relay' );
}

diag( "Testing FreeMED::Relay $FreeMED::Relay::VERSION, Perl $], $^X" );
