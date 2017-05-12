#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::Sudoku::CPSearch' );
}

diag( "Testing Games::Sudoku::CPSearch $Games::Sudoku::CPSearch::VERSION, Perl $], $^X" );
