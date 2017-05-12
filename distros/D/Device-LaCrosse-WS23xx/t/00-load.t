#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Device::LaCrosse::WS23xx' );
}

diag( "Testing Device::LaCrosse::WS23xx $Device::LaCrosse::WS23xx::VERSION, Perl $], $^X" );
