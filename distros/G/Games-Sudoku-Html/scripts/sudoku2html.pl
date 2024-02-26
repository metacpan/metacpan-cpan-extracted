#!/usr/bin/env perl
use strict;
use warnings;

use Games::Sudoku::Html qw( sudoku_html_page );
our $VERSION = $Games::Sudoku::Html::VERSION;

BEGIN {
  require Getopt::Std;
  $| = 1;
}

my $script_name = $0;
$script_name =~ s|^.+/||;
my $opts = {};
Getopt::Std::getopts('i:D:F:o:', $opts) or die usage();
usage() if $opts->{h};

if ($opts->{i}) {
  push @ARGV, $opts->{i};
}

my $quiet = $opts->{o} ? 0 : 1;

my $delim = $opts->{D} || ';';
my $line_format = $opts->{F} || join $delim, 'C', 'D';

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

my $del_line = ''; #"\r" . (' ' x 80) . "\r";

my @puzzles = ();
my $count = 0;
while (<>) {
  chomp;
  @line = split / *\Q$delim\E */o, $_;

  my $clues = $line[$positions{C}];
  length($clues) == 81 or next;

  my $description;
  if (exists($positions{D}) && $line[$positions{D}]) {
     $description = $line[$positions{D}];
  }
  $count++;
  push @puzzles, [$clues, $description];
  print $del_line, sprintf "  %3d) %s\t%s\n", 
    $count, $clues, $description
    unless $quiet;
}

if (@puzzles) {
  if ($opts->{o}) {
    # print to file
    open my $hdl, '>', $opts->{o} or die "Opening '$opts->{o}' for writing:\n$!\n";
    print $hdl sudoku_html_page( \@puzzles );
    close $hdl;

  } else {
    #  print to stdout
    print sudoku_html_page( \@puzzles );
  }
} else {
  warn "No sudoku puzzles could be read from input. Omitting output.\n";
  exit 1;
}

exit 0;

sub usage {
    print <<EOM;
Usage:
  $script_name [OPTIONS] my_sudokus.txt > my_sudokus.html
  $script_name [OPTIONS] -i my_sudokus.txt -o my_sudokus.html
  producer | $script_name [OPTIONS] > my_sudokus.html

Read lines with sudoku puzzles from file(s) or pipe and turn them into a single static html file to open and play in a browser.
The producer may be a generator like e.g. sudogen (see Games::Sudoku::PatternSolver) or a re-formatter.

OPTIONS

  -i  A text file with one sudoku puzzle per line to read from.
      Reads from stdin if none was specified.

  -D  The character used to separate the defining string of given clues from further parameters. Can be '|', ':', ';', ',' or 'T' (tab).
      Default is the semikolon ';'.
  -F  A string that specifies the order of parameters (line format), using the specified delimiter.
      Default is 'C;D', where 
          C is the 81 character string of clues (givens), empty cells denoted by '.', '0', ' '.
          D is the descriptive text string to put in the bottom line under the puzzle.

  -o  A html file to write to.

  -h  Display this help.

Copyright (c) 2024 Steffen Heinrich. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

EOM
    exit 0;
}
