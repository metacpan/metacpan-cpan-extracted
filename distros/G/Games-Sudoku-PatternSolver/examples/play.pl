#!/usr/bin/env perl

use strict;
use warnings;

use Games::Sudoku::PatternSolver::Generator qw( get_sudoku_builder );
use Games::Sudoku::PatternSolver::PlayerIF  qw( sudoku_html_page );

$Games::Sudoku::PatternSolver::Generator::LOOSE_MODE = 1;

my $to_create = $ARGV[0] || 5;
my $file = './play_my_sudoku.html';

my $generator = get_sudoku_builder();

my @buffer = ();

for (my $count = 1; $count <= $to_create; $count++) {
  my $sudoku = &$generator();

  # inspect the puzzle properties and skip undesired results
  # format a descriptive text to your liking

  my $singles_percentage = $sudoku->{logicFilled} * 100 / (81-$sudoku->{givensCount});
  my $level = $Games::Sudoku::PatternSolver::USE_LOGIC ? ($sudoku->{logicSolved} ? $sudoku->{candidatesDropped} ? 'Advanced' : 'Easy' : 'Master') : '--na--';

  printf "  %3d) %s\t%d(%d)\t%s\n", $count, $sudoku->{strPuzzle}, $sudoku->{uniqueGivens}, $sudoku->{givensCount}, $level;

  my $description = sprintf('(%d givens of %d), %d%% solved by singles, %s', $sudoku->{givensCount}, $sudoku->{uniqueGivens}, $singles_percentage, $level);

  push @buffer, [$sudoku->{strPuzzle}, $description];
}

if (my $page = sudoku_html_page(\@buffer)) {
  open my $export, '>:utf8', $file or die "Open '$file':\n" . $!;
  print $export $page;
  print "You may now open '$file' in your browser\n";
}
