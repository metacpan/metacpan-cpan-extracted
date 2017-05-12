#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::Othello' );
}

diag( "Testing Games::Othello $Games::Othello::VERSION, Perl $], $^X" );
