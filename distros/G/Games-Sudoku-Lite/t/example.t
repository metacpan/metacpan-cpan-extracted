#!/usr/bin/perl
# vim:ft=perl
use strict;
use warnings;
use Test::More 'no_plan';

use lib 'lib';
use Games::Sudoku::Lite;

my $board = <<END;
3....8.2.
.....9...
..27.5...
24.5..8..
.85.74..6
.3....94.
1.4....72
..69...5.
.7.612..9
END

my $puzzle = Games::Sudoku::Lite->new($board);
   $puzzle->solve;

my $solution = <<END;
359168724
718429563
462735198
241596837
985374216
637281945
194853672
826947351
573612489
END

is ($puzzle->solution, $solution);


