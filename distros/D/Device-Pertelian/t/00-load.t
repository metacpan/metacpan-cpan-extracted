#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Device::Pertelian' );
}

diag( "Testing Device::Pertelian $Device::Pertelian::VERSION, Perl $], $^X" );
