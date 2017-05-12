#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Makefile::Parallel' );
}

diag( "Testing Makefile::Parallel $Makefile::Parallel::VERSION, Perl $], $^X" );
