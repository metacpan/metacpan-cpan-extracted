#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::Maze::SVG' );
}

diag( "Testing Games::Maze::SVG $Games::Maze::SVG::VERSION, Perl $], $^X" );
