#!/usr/bin/perl
# vim:ft=perl
use strict;
use warnings;
use Test::More 'no_plan';

use lib 'lib';
use Games::Sudoku::Lite;

my $board = <<END;
....B.U.D
U..K..G..
.A...C.O.
......CE.
..B.....O
AEO.G..K.
..G.OK...
.C.D....U
.U.B.G...
END
 
my %config = (
    possible_values => [qw(G O D A K C U B E)],
);
my $puzzle = Games::Sudoku::Lite->new($board, \%config );
   $puzzle->solve;

my $soln = <<END;
GKEABOUCD
UOCKDEGBA
BADGUCKOE
KDUOABCEG
CGBEKDAUO
AEOCGUDKB
DBGUOKEAC
OCKDEABGU
EUABCGODK
END
is ($puzzle->solution, $soln, "Godoku board works.");
is ($puzzle->validate, '', "Godoku board ... no errors.");

