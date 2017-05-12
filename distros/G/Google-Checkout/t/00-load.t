#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Google::Checkout::General::GCO' );
}

diag( "Testing GCO $GCO::VERSION, Perl $], $^X" );

