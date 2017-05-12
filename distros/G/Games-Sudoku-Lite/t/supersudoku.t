#!/usr/bin/perl
# vim:ft=perl
use strict;
use warnings;
use Test::More 'no_plan';

use lib 'lib';
use Games::Sudoku::Lite;

my $board = <<END;
.2E08.1..9.4..B.
7.........AB1F.C
..F.0E......7..D
B4...F..027....5
.1...867D..9B...
5......C3.B..A..
.8BA......1...C2
E06.......FA4.98
6...EA....5DC.70
..C9103......42.
.71D5...2....9.F
.B.....948..6...
.....20..5..F...
.A3..1C6.D...0..
1C8.D54......7E.
09.F3...E....C..
END
 
my %config = (
    height          => 16,
    width           => 16,
    square_height   => 4,
    square_width    => 4,
    possible_values => [0..9,'A'..'F'],
    DEBUG           => 0,
);
my $puzzle = Games::Sudoku::Lite->new($board, \%config );
   $puzzle->solve;

my $soln = <<END;
C2E08715F9D4A3B6
75D364928EAB1F0C
96F80EBA13C5724D
B4A1CFD302769E85
314CA867D029B5FE
5F924DEC36B80A17
D8BAF950741E36C2
E067B3215CFA4D98
6324EAFB915DC870
8EC9103DAF67542B
A71D56842B0CE93F
FB052C7948E361DA
4D76920EC581FBA3
2A3E71C6BD9F8054
1C8BD54F6A3027E9
095F3BA8E742DC61
END
is ($puzzle->solution, $soln, "16x16 board works.");
is ($puzzle->validate, '', "16x16 board ... no errors.");

