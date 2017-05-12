#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use Games::Sudoku::Kubedoku;

my $sudoku;

$sudoku = Games::Sudoku::Kubedoku->new('1.34....432.21.3');
$sudoku->solve();
is($sudoku->get_game(), '1234341243212143', "Sudoku 4x4");

$sudoku = Games::Sudoku::Kubedoku->new('.4...7.35..5...8.7.78.65.9.9..2..3....364.7.9.6..3.2..5.....1...9.7.......235...4');
$sudoku->solve();
is($sudoku->get_game(), '149827635625493817378165492954278361283641759761539248537984126496712583812356974', "Sudoku 9x9");

$sudoku = Games::Sudoku::Kubedoku->new('ad4...67..3b.c.....c9a.2.1..........5...g46..2.d....c.319...g.7.....a758..b..e....1...........9..g.d....e6f.c.1537b6.e2.5........e....1.7....5...f.7..c..b9........3e..4fg...6a.g4.8.b7...e3.9..4a....b6.e.f7...25f.......1.3..a.c3...g..a5.4d.b.6.128.3........');
$sudoku->solve();
is($sudoku->get_game(), 'ad4f8g67253b9ce16bgc9ad2817e534f13795febg46ca28d58e2c4319fdagb76f9c4a75813bd6eg2e215g6fdc8a7b4938gadb349e6f2c71537b61e2c59g4daf8ce2a391g7d86f5b4df5762ca4b918g3eb193ed84fgc526a7g468fb75a2e319dc4a8gd5b63e2f71c925fb4c9ed71g386a9c3e71gf6a584d2b76d128a3bc49ef5g', "Sudoku 16x16");
