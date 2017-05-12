#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::Kwiki' );
}

diag( "Testing HTML::WikiConverter::Kwiki $HTML::WikiConverter::Kwiki::VERSION, Perl $], $^X" );
