#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FTN::Packet' );
}

diag( "Testing FTN::Packet $FTN::Packet::VERSION, Perl $], $^X" );
