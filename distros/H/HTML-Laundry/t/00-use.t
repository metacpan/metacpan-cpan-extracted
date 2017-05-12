#!perl

use Test::More tests => 4;

BEGIN {
	use_ok( 'HTML::Laundry' );
	use_ok( 'HTML::Laundry::Rules' );
	use_ok( 'HTML::Laundry::Rules::Default' );
	use_ok( 'HTML::Laundry::Rules::Minimal' );
}

diag( "Testing HTML::Laundry $HTML::Laundry::VERSION, Perl $], $^X" );
