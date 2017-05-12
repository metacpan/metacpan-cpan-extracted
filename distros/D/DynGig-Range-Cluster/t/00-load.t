#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DynGig::Range::Cluster' );
}

diag( "Testing DynGig::Range::Cluster $DynGig::Range::Cluster::VERSION, Perl $], $^X" );
