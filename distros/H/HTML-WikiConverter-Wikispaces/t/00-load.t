#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::Wikispaces' );
}

diag( "Testing HTML::WikiConverter::Wikispaces $HTML::WikiConverter::Wikispaces::VERSION, Perl $], $^X" );
