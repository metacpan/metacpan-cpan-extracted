#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Locale::Country::Geo' );
}

diag( "Testing Locale::Country::Geo $Locale::Country::Geo::VERSION, Perl $], $^X" );
