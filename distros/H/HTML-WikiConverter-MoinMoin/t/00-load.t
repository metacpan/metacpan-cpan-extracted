#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::MoinMoin' );
}

diag( "Testing HTML::WikiConverter::MoinMoin $HTML::WikiConverter::MoinMoin::VERSION, Perl $], $^X" );
