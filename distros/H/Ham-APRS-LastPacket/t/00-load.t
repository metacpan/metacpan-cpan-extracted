#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Ham::APRS::LastPacket' );
}

diag( "Testing Ham::APRS::LastPacket $Ham::APRS::LastPacket::VERSION, Perl $], $^X" );
