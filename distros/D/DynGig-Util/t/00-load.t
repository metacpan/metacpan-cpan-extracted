#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DynGig::Util' );
}

diag( "Testing DynGig::Util $DynGig::Util::VERSION, Perl $], $^X" );
