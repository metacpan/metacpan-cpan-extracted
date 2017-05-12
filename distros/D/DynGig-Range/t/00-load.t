#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DynGig::Range' );
}

diag( "Testing DynGig::Range $DynGig::Range::VERSION, Perl $], $^X" );
