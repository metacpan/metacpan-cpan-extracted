#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DynGig::Automata' );
}

diag( "Testing DynGig::Automata $DynGig::Automata::VERSION, Perl $], $^X" );
