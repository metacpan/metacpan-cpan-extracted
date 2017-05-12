#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::Oddmuse' );
}

diag( "Testing HTML::WikiConverter::Oddmuse $HTML::WikiConverter::Oddmuse::VERSION, Perl $], $^X" );
