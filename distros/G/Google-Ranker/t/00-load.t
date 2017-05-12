#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Google::Ranker' );
}

diag( "Testing Google::Ranker $Google::Ranker::VERSION, Perl $], $^X" );
