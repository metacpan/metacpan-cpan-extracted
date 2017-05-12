#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Locale::Country::Multilingual' );
}

diag( "Testing Locale::Country::Multilingual $Locale::Country::Multilingual::VERSION, Perl $], $^X" );
