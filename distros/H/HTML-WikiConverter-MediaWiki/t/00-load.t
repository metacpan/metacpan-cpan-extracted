#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::MediaWiki' );
}

diag( "Testing HTML::WikiConverter::MediaWiki $HTML::WikiConverter::MediaWiki::VERSION, Perl $], $^X" );
