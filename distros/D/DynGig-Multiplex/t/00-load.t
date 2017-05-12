#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DynGig::Multiplex' );
}

diag( "Testing DynGig::Multiplex $DynGig::Multiplex::VERSION, Perl $], $^X" );
