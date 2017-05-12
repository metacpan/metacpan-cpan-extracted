#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gpx::Addons::Filter' );
}

diag( "Testing Gpx::Addons::Filter $Gpx::Addons::Filter::VERSION, Perl $], $^X" );
