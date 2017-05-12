#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::TikiWiki' );
}

diag( "Testing HTML::WikiConverter::TikiWiki $HTML::WikiConverter::TikiWiki::VERSION, Perl $], $^X" );
