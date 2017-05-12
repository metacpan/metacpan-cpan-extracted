#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::DokuWiki' );
}

diag( "Testing HTML::WikiConverter::DokuWiki $HTML::WikiConverter::DokuWiki::VERSION, Perl $], $^X" );
