#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::SnipSnap' );
}

diag( "Testing HTML::WikiConverter::SnipSnap $HTML::WikiConverter::SnipSnap::VERSION, Perl $], $^X" );
