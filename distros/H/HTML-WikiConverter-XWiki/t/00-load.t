#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::XWiki' );
}

diag( "Testing HTML::WikiConverter::XWiki $HTML::WikiConverter::XWiki::VERSION, Perl $], $^X" );
