#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Ham::Reference::QRZ' );
}

diag( "Testing Ham::Reference::QRZ $Ham::Reference::QRZ::VERSION, Perl $], $^X" );
