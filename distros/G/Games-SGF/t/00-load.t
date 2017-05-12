#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::SGF' );
}

diag( "Testing Games::SGF $Games::SGF::VERSION, Perl $], $^X" );
