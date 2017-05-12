#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DynGig::RCE' );
}

diag( "Testing DynGig::RCE $DynGig::RCE::VERSION, Perl $], $^X" );
