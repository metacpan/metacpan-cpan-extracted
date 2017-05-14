#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use Games::Sudoku::Kubedoku;

my $sudoku = Games::Sudoku::Kubedoku->new();

$sudoku->set_value(1,1,1);
is($sudoku->get_game(), '1................................................................................', 'Setting Value 1');

$sudoku->set_value(9,9,9);
is($sudoku->get_game(), '1...............................................................................9', 'Setting Value 9');

my $game = $sudoku->clone_data_struc();
is($game->{'kube'}->[0][0][0], 671, "Unknown Kube Values");
is($game->{'result'}->[0][0], 2, "Known Result Values");
