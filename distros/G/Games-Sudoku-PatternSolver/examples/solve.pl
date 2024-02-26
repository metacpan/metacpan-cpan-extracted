#!/usr/bin/env perl

use strict;
use warnings;

use Games::Sudoku::PatternSolver qw( :all );

$MAX_SOLUTIONS = 2;
$VERBOSE       = 1;
$LOOSE_MODE    = 1;
$USE_LOGIC     = 1;

my $puzzle = $ARGV[0] || '74...9.........479..12....8..2..3.......28..7...9.1.8..3....2..98.4....11....7...';

print 
  "######################################\n",
  "verbose output of the solving process:\n",
  "######################################\n";

solve( $puzzle );

print 
  "#####################################\n",
  "explicit use of print_grid() instead:\n",
  "#####################################\n";

$VERBOSE = 0;

my $res = solve( $puzzle );

print_grid( $res->{solutions}[0] );

