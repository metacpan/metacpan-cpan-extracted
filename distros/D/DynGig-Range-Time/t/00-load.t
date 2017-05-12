#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DynGig::Range::Time' );
}

diag( "Testing DynGig::Range::Time $DynGig::Range::Time::VERSION, Perl $], $^X" );
