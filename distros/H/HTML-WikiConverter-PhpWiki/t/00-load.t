#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::PhpWiki' );
}

diag( "Testing HTML::WikiConverter::PhpWiki $HTML::WikiConverter::PhpWiki::VERSION, Perl $], $^X" );
