#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::Maze::FirstPerson' );
}

diag( "Testing Games::Maze::FirstPerson $Games::Maze::FirstPerson::VERSION, Perl $], $^X" );
