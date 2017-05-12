#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::WikkaWiki' );
}

diag( "Testing HTML::WikiConverter::WikkaWiki $HTML::WikiConverter::WikkaWiki::VERSION, Perl $], $^X" );
