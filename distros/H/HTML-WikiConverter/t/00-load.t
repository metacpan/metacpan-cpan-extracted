#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter' );
}

diag( "Testing HTML::WikiConverter $HTML::WikiConverter::VERSION, Perl $], $^X" );
