#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::UseMod' );
}

diag( "Testing HTML::WikiConverter::UseMod $HTML::WikiConverter::UseMod::VERSION, Perl $], $^X" );
