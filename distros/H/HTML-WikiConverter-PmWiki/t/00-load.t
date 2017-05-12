#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::PmWiki' );
}

diag( "Testing HTML::WikiConverter::PmWiki $HTML::WikiConverter::PmWiki::VERSION, Perl $], $^X" );
