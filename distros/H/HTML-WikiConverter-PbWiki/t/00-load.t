#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::PbWiki' );
}

diag( "Testing HTML::WikiConverter::PbWiki $HTML::WikiConverter::PbWiki::VERSION, Perl $], $^X" );