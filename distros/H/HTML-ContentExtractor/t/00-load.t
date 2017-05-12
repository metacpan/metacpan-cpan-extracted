#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'HTML::ContentExtractor' );
}

diag( "Testing HTML::ContentExtractor $HTML::ContentExtractor::VERSION, Perl $], $^X" );
