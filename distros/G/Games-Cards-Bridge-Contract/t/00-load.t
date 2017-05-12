#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::Cards::Bridge::Contract' );
}

diag( "Testing Games::Cards::Bridge::Contract $Games::Cards::Bridge::Contract::VERSION, Perl $], $^X" );
