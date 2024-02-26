#!/usr/bin/env perl

use strict;
use warnings;

use Games::Sudoku::PatternSolver::Generator qw( get_sudoku_builder );
use Games::Sudoku::Html  qw( sudoku_html_page );

$Games::Sudoku::PatternSolver::Generator::LOOSE_MODE = 1;

my $to_create = $ARGV[0] || 5;
my $file = './play_my_sudoku.html';

my $generator = get_sudoku_builder();

my @buffer = ();

for (my $count = 1; $count <= $to_create; $count++) {
  my $sudoku = &$generator();

  # inspect the puzzle properties and skip undesired results
  # format a descriptive text to your liking

  my ($level, $level_description);
  if ($Games::Sudoku::PatternSolver::USE_LOGIC) {
    if ($sudoku->{logicSolved}) {
      if ($sudoku->{candidatesDropped}) {
        $level = 'Advanced';
        $level_description = 'solved with simple logic';
      } else {
        $level = 'Easy';
        $level_description = 'solved all by singles';
      }
    } else {
      $level = 'Master';
      my $logic_percentage = $sudoku->{logicFilled} * 100 / (81-$sudoku->{givensCount});
      $level_description = sprintf 'could solve %d%% before using trial and error', $logic_percentage;
    }
  } else {
    $level = '-- na --';
    $level_description = 'without \$USE_LOGIC, no ranking is possible';
  }

  printf "  %3d) %s\t%d(%d)\t%s - (%s)\n", $count, $sudoku->{strPuzzle}, $sudoku->{uniqueGivens}, $sudoku->{givensCount}, $level_description, $level;

  my $description = sprintf('(%d givens of %d), %s, %s', $sudoku->{givensCount}, $sudoku->{uniqueGivens}, $level_description, $level);

  push @buffer, [$sudoku->{strPuzzle}, $description];
}

if (my $page = sudoku_html_page(\@buffer)) {
  open my $export, '>:utf8', $file or die "Open '$file':\n" . $!;
  print $export $page;
  print "You may now open '$file' in your browser\n";
}
