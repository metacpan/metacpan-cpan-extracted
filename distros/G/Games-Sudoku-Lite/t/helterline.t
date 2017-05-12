#!/usr/bin/perl
# vim:ft=perl
use strict;
use warnings;
use Test::More 'no_plan';

use lib 'lib';
use Games::Sudoku::Lite;

my $board = <<END;
6.3...
...6.4
4.25..
..42.5
2.6...
...3.6
END
 
my %config = (
    height          => 6,
    width           => 6,
    square_height   => 3,
    square_width    => 2,
    possible_values => [1..6],
    DEBUG           => 0,
);
my $puzzle = Games::Sudoku::Lite->new($board, \%config );
   $puzzle->solve;

my $soln = <<END;
613452
521634
432561
364215
256143
145326
END
is ($puzzle->solution, $soln, "6x6 board works.");
is ($puzzle->validate, '', "6x6 board ... no errors.");

