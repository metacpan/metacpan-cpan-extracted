#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'KSx::Searcher::Abstract' );
}

diag( "Testing KSx::Searcher::Abstract $KSx::Searcher::Abstract::VERSION, Perl $], $^X" );
