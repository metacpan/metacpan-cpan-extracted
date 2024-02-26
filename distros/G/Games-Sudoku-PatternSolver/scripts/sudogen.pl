#!/usr/bin/env perl
use strict;
use warnings;

use Games::Sudoku::PatternSolver::Generator;
our $VERSION = $Games::Sudoku::PatternSolver::VERSION;
$Games::Sudoku::PatternSolver::Generator::LOOSE_MODE = 1;

BEGIN {
  require Getopt::Std;
  $| = 1;
}

my $script_name = $0;
$script_name =~ s|^.+/||;
my $opts = {};
Getopt::Std::getopts('D:F:C:L:G:T:Qo:a:', $opts) or die usage();
usage() if $opts->{h};

my $to_create = $opts->{C} || 50;
my $file = $opts->{o} || $opts->{a};
my ($out_hdl, $quiet);
if ($file) {
  open $out_hdl, ($opts->{a} ? '>>' : '>'), $file or die "$file:\n$!\n";
  $quiet = $opts->{Q};
} else {
  $out_hdl = *STDOUT;
  $quiet = 1;
}
if (defined $opts->{L}) {
  $Games::Sudoku::PatternSolver::Generator::LOOSE_MODE = $opts->{L} ? 1 : 0;
}
my $filter_level = '';
if ($opts->{G}) {
  if (uc($opts->{G}) eq 'E') {
    $filter_level = 'Easy';
  } elsif (uc($opts->{G}) eq 'A') {
    $filter_level = 'Advanced';
  } elsif (uc($opts->{G}) eq 'M') {
    $filter_level = 'Master';
  }
}

my $delim = $opts->{D} || ';';
my $line_format = $opts->{F} || join $delim, 'C', 'D';
my $description_template = $opts->{T} || '# %#: %L - %U / %C clues';

my %positions = ();
my $i = 0;
my @line = split / *\Q$delim\E */, $line_format;
foreach my $s (@line) {
  if ($s =~ /C|D/) {
    $positions{$s} = $i;
  }
  $i++;
}
$delim = "\t" if $delim eq 'T';
exists $positions{C} or die "Position C(lues) is missing in the output format '$opts->{F}'\n";

my $generator = Games::Sudoku::PatternSolver::Generator::get_sudoku_builder();

my $del_line = ''; #"\r" . (' ' x 80) . "\r";
{
  my $break = 0;
  local $SIG{INT} = sub {$break = 1; print "Received user break, waiting for generator to halt.\n" unless $quiet;};
  print "You may stop adding further Sudoku by pressing Ctrl+C !\n-------------------------------------------------------\n"
    unless $quiet;

  for (my $count = 0; $count < $to_create;) {
    my $sudoku = &$generator();
    last if $break;

    my ($level, $level_description);
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

    next if ($filter_level && $filter_level ne $level);
    $count++;

    print $del_line, sprintf "  %3d) %s\t%d(%d)\t%s - (%s)\n", 
      $count, $sudoku->{strPuzzle}, $sudoku->{uniqueGivens}, $sudoku->{givensCount}, $level_description, $level
      unless $quiet;

    $line[$positions{C}] = $sudoku->{strPuzzle};
    if (exists $positions{D}) {
      $line[$positions{D}] = get_description($description_template, $count, $level, $sudoku->{givensCount}, $sudoku->{uniqueGivens});
    }
    print $out_hdl join($delim, @line), "\n";
  }
}
exit 0;

sub get_description {
  my ($template, $count, $level, $clues, $unique) = @_;

  $template =~ s/%#/$count/g;
  $template =~ s/%L/$level/g;
  $template =~ s/%C/$clues/g;
  $template =~ s/%U/$unique/g;

  return $template
}

sub usage {
    print <<EOM;
Usage:
  $script_name [OPTIONS]  > my_sudokus.txt
  $script_name [OPTIONS] -o my_sudokus.txt
  $script_name [OPTIONS] -

Generate standard 9x9 Sudoku with properties defined by options and write them to file or stdout.

OPTIONS

  -o  A text file to write to.
  -a  An existing text file to append to.
      Writes to stdout if neither was specified.

  -D  The character separating the sudoku parameters in each output line. Can be '|', ':', ';', ',' or 'T' (tab).
      Default is the semikolon ';'.
  -F  A string that specifies the order of parameters (line format), using the specified delimiter.
      Default is 'C;D', where 
          C is the 81 character string of given clues, empty cells denoted by '.', '0', ' '.
          D is the descriptive text string to put in the bottom line under the puzzle.
      The default format is compatible with the default input format of sudoku2pdf (Games::Sudoku::Pdf) 
      and sudoku2html (Games::Sudoku::Html).

  -C How many Sudoku to create. Defaults to 50.
  -L LOOSE_MODE, a value of 0 or 1. Whether to allow puzzles with less than 8 different numbers given as clues. 
     Default 1, allow.
  -G Only puzzles with a certain difficulty grading: Single letter of E(asy), A(dvanced), M(aster).
  -T Descriptive text template where 
     %# is the sequential number
     %L is the difficulty as attributed by generator [Easy|Advanced|Master]
     %C is the number of clues in the puzzle
     %U is the number of different clues in the puzzle

  -Q Quiet. No output to console, even when writing to files.

  -h  Display this help.

Copyright (c) 2024 Steffen Heinrich. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

EOM
    exit 0;
}
