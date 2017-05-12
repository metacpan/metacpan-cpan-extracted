#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::WikiConverter::Confluence' );
}

diag( "Testing HTML::WikiConverter::Confluence $HTML::WikiConverter::Confluence::VERSION, Perl $], $^X" );
