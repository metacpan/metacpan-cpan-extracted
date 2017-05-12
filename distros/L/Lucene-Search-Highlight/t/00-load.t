#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Lucene::Search::Highlight' );
}

diag( "Testing Lucene::Search::Highlight $Lucene::Search::Highlight::VERSION, Perl $], $^X" );
