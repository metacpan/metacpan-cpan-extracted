#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Games::Sudoku::Preset' ) || print "Bail out!\n";
}

diag( "Testing Games::Sudoku::Preset $Games::Sudoku::Preset::VERSION, Perl $], $^X" );
