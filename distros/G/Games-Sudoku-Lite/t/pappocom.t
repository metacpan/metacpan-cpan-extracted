#!/usr/bin/perl
# vim:ft=perl
use strict;
use warnings;
use Test::More 'no_plan';

use lib 'lib';
use Games::Sudoku::Lite;

my $board = <<END;
.F6...A..12.4C.
..1.5.9..7.....
.2A.CD64..1B...
.B.6E...DC..97.
C.3....8.E.A.6.
.7D.86...BE....
...E2.8..F....B
7.4.........2.D
A....9..2.C6...
....15...9D.BA.
.E.5.B.7....3.6
.89..12...45.E.
...F4..6AD7.E8.
.....7..1.3.A..
.AB.38..9...F2.
END
 
my %config = (
    height          => 15,
    width           => 15,
    square_height   => 3,
    square_width    => 5,
    possible_values => [1..9,'A'..'F'],
);
my $puzzle = Games::Sudoku::Lite->new($board, \%config );
   $puzzle->solve;

my $soln = <<END;
DF687EAB51294C3
B413529C87FE6DA
E2A9CD64F31B857
4BF6EA12DC53978
C1329F587EBAD64
57DA86493BE2CF1
9DCE24816FA753B
75416CE3BA8F29D
A38BF97D25C614E
6C74153FE9D8BA2
FE25ABD7489C316
389DB12AC6457EF
295F43B6AD71E8C
86ECD7F51234AB9
1AB738CE946DF25
END
is ($puzzle->solution, $soln, "15x15 board works.");
is ($puzzle->validate, '', "15x15 board ... no errors.");


