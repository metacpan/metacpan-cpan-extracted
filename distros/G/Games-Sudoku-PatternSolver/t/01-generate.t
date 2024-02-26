#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use Games::Sudoku::PatternSolver::Generator;

$Games::Sudoku::PatternSolver::LOOSE_MODE = 1;

my $grid_builder = Games::Sudoku::PatternSolver::Generator::get_grid_builder();

my $grid = &$grid_builder(0);

like($grid, qr/^123456789[1-9]{72}$/, "grid not shuffled"); 

my $sudoku_builder = Games::Sudoku::PatternSolver::Generator::get_sudoku_builder($grid, undef, 0);
my $sudoku = &$sudoku_builder();

is($sudoku->{solutionCount}, 1, "generated puzzle is valid");

cmp_ok($sudoku->{givensCount}, '<', 30, "grid was modified");

my $solution = $sudoku->{solutions}[0];

if ($solution =~ s/[^1-9]/\[1-9\]/g) {
	like($grid, qr/^$solution$/, "seed grid still matches solution");
	
} else {
	is($solution, $grid, "solution equals seed grid");
}
