#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

use Games::Sudoku::PatternSolver qw( solve $VERBOSE $MAX_SOLUTIONS $LOOSE_MODE $USE_LOGIC );

my $sudoku;

$VERBOSE = 0;
$MAX_SOLUTIONS = 2;
$LOOSE_MODE = 0;
$USE_LOGIC = 1;

my $seven_givens = '.......6.5.....4.72.9..485..86....9......7......6.2.8.795........2....754....9...'; # 1 solution
my $six_givens   = '1.72.836.2.836..7136..71.82.71.826.3.826.371.6.371.82.71.82..3682..361.7.361.72.8'; # 2 solutions
my $five_givens  = '1...2...3.4.............21....2...3..2....5..5...13.4..1..34...3...5....2.......5'; # 1 solution

my $result = solve($seven_givens);
is($result, 0, "warns underdetermined");

$LOOSE_MODE = 1;
$result = solve($seven_givens);

is($result->{solutionCount}, 1, "accepted with loose mode");

is($result->{candidatesDropped}, 21, "candidates were dropped");

$result = solve($six_givens);
is($result->{solutionCount}, 2, "solves 6 givens");

$MAX_SOLUTIONS = 1;
$result = solve($six_givens);
is($result->{solutionCount}, 1, "obeys max_solutions");

$MAX_SOLUTIONS = undef;
$result = solve($five_givens);
is($result->{solutionCount}, 1, "solves 5 givens");

my $solution = $result->{solutions}[0];
like($solution, qr/D/, "multiple dropin symbols"); 
