#!perl
use strict;
use warnings;

use Test::More tests => 122;
use FindBin qw( $Bin );
use File::Spec::Functions;
use Config;

use Games::AlphaBeta;
use Games::AlphaBeta::Reversi;

my $perl = $Config{perlpath};
my $othello = catfile( $Bin, qw(.. bin othello-demo) );
my $lib = catfile( $Bin, qw(.. lib) );

local $/ = "\n\n";
my @states = qx( $perl -I$lib $othello ) 
  or die 'running trace helper failed';

my $p = Games::AlphaBeta::Reversi->new;
my $g = Games::AlphaBeta->new($p);

while ($p = $g->abmove) {
  my $state = $p->as_string . "\n";
  is $state, shift @states;
  is $state, <DATA>;
}

__DATA__
     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . . o . . .
 4 | . . . o o . . .
 5 | . . . x o . . .
 6 | . . . . . . . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . . o . . .
 4 | . . . o o . . .
 5 | . . . x x x . .
 6 | . . . . . . . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . . o . . .
 4 | . . . o o . . .
 5 | . . . o x x . .
 6 | . . o . . . . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . x o . . .
 4 | . . . o x . . .
 5 | . . . o x x . .
 6 | . . o . . . . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . x o . . .
 4 | . . . o o . . .
 5 | . . . o o x . .
 6 | . . o . o . . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . x o . . .
 4 | . . . x o . . .
 5 | . . . x o x . .
 6 | . . o x o . . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . x o . . .
 4 | . . . o o . . .
 5 | . . o o o x . .
 6 | . . o x o . . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . x o . . .
 4 | . . . o o x . .
 5 | . . o o x x . .
 6 | . . o x o . . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . x o . . .
 4 | . . . o o x . .
 5 | . . o o o x . .
 6 | . . o x o o . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . x o . . .
 4 | . . x x x x . .
 5 | . . o o o x . .
 6 | . . o x o o . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . x o . . .
 4 | . . x x x x o .
 5 | . . o o o o . .
 6 | . . o x o o . .
 7 | . . . . . . . .
 8 | . . . . . . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . . . . . . .
 3 | . . . x o . . .
 4 | . . x x x x o .
 5 | . . o o x o . .
 6 | . . o x x o . .
 7 | . . . . x . . .
 8 | . . . . . . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . o . . . . .
 3 | . . . o o . . .
 4 | . . x x o x o .
 5 | . . o o x o . .
 6 | . . o x x o . .
 7 | . . . . x . . .
 8 | . . . . . . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . . . . . . . .
 2 | . . o x . . . .
 3 | . . . x x . . .
 4 | . . x x o x o .
 5 | . . o o x o . .
 6 | . . o x x o . .
 7 | . . . . x . . .
 8 | . . . . . . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . . . o . . . .
 2 | . . o o . . . .
 3 | . . . o x . . .
 4 | . . x o o x o .
 5 | . . o o x o . .
 6 | . . o x x o . .
 7 | . . . . x . . .
 8 | . . . . . . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . . x o . . . .
 2 | . . o x . . . .
 3 | . . . o x . . .
 4 | . . x o o x o .
 5 | . . o o x o . .
 6 | . . o x x o . .
 7 | . . . . x . . .
 8 | . . . . . . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . . o x . . . .
 3 | . . . o x . . .
 4 | . . x o o x o .
 5 | . . o o x o . .
 6 | . . o x x o . .
 7 | . . . . x . . .
 8 | . . . . . . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . . o x x . . .
 3 | . . . x x . . .
 4 | . . x o o x o .
 5 | . . o o x o . .
 6 | . . o x x o . .
 7 | . . . . x . . .
 8 | . . . . . . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . . o x x . . .
 3 | . . . x x . . .
 4 | . . x o o x o .
 5 | . . o o o o . .
 6 | . . o x o o . .
 7 | . . . . o . . .
 8 | . . . . o . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x x x x . . .
 3 | . . . x x . . .
 4 | . . x o o x o .
 5 | . . o o o o . .
 6 | . . o x o o . .
 7 | . . . . o . . .
 8 | . . . . o . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . o x x . . .
 4 | . . o o o x o .
 5 | . . o o o o . .
 6 | . . o x o o . .
 7 | . . . . o . . .
 8 | . . . . o . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x . . .
 4 | . . o x o x o .
 5 | . . o o x o . .
 6 | . . o x o x . .
 7 | . . . . o . x .
 8 | . . . . o . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x . . .
 4 | . . o x o x o .
 5 | . . o o x o . .
 6 | . . o x o o . .
 7 | . . . . o o x .
 8 | . . . . o . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x . . .
 4 | . . o x x x o .
 5 | . . o o x x . .
 6 | . . o x x x x .
 7 | . . . . o o x .
 8 | . . . . o . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x . . .
 4 | . . o x x x o .
 5 | . . o o x o . .
 6 | . . o o o x x .
 7 | . . . o o o x .
 8 | . . . . o . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x . . .
 4 | . . o x x x o .
 5 | . . o o x x x .
 6 | . . o o o x x .
 7 | . . . o o o x .
 8 | . . . . o . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x . o .
 4 | . . o x x o o .
 5 | . . o o o x x .
 6 | . . o o o x x .
 7 | . . . o o o x .
 8 | . . . . o . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x x o .
 4 | . . o x x x o .
 5 | . . o o o x x .
 6 | . . o o o x x .
 7 | . . . o o o x .
 8 | . . . . o . . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x x o .
 4 | . . o x x x o o
 5 | . . o o o x o .
 6 | . . o o o o x .
 7 | . . . o o o x .
 8 | . . . . o . . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x x o .
 4 | . . o x x x o o
 5 | . . o o o x o .
 6 | . . o o o x x .
 7 | . . . o o x x .
 8 | . . . . o x . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . .
 3 | . . x x x x o .
 4 | . . o x x x o o
 5 | . . o o o x o o
 6 | . . o o o x o .
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o . . . .
 2 | . x o x x . . x
 3 | . . x x x x x .
 4 | . . o x x x o o
 5 | . . o o o x o o
 6 | . . o o o x o .
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o o . . .
 2 | . x o x o . . x
 3 | . . x x o x x .
 4 | . . o x o x o o
 5 | . . o o o x o o
 6 | . . o o o x o .
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o o . . .
 2 | . x o x o . . x
 3 | . . x x o x x x
 4 | . . o x o x x o
 5 | . . o o o x o o
 6 | . . o o o x o .
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o o . . o
 2 | . x o x o . . o
 3 | . . x x o x x o
 4 | . . o x o x x o
 5 | . . o o o x o o
 6 | . . o o o x o .
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o o x . o
 2 | . x o x x . . o
 3 | . . x x o x x o
 4 | . . o x o x x o
 5 | . . o o o x o o
 6 | . . o o o x o .
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o o o o o
 2 | . x o x x . . o
 3 | . . x x o x x o
 4 | . . o x o x x o
 5 | . . o o o x o o
 6 | . . o o o x o .
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o o o o o
 2 | . x o x x x . o
 3 | . . x x x x x o
 4 | . . o x o x x o
 5 | . . o o o x o o
 6 | . . o o o x o .
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o o o o o
 2 | . x o o o o o o
 3 | . . x x x o o o
 4 | . . o x o x o o
 5 | . . o o o x o o
 6 | . . o o o x o .
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | . o o o o o o o
 2 | . x o o o o o o
 3 | . . x x x o o o
 4 | . . o x o x o o
 5 | . . o o o x x o
 6 | . . o o o x x x
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | . o o o o o o o
 2 | o o o o o o o o
 3 | . . x x x o o o
 4 | . . o x o x o o
 5 | . . o o o x x o
 6 | . . o o o x x x
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | o x o o o o o o
 3 | . . x x x o o o
 4 | . . o x o x o o
 5 | . . o o o x x o
 6 | . . o o o x x x
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | o o o o o o o o
 3 | o . x x x o o o
 4 | . . o x o x o o
 5 | . . o o o x x o
 6 | . . o o o x x x
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x . x x x o o o
 4 | x . o x o x o o
 5 | . . o o o x x o
 6 | . . o o o x x x
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x . o x o x o o
 5 | . . o o o x x o
 6 | . . o o o x x x
 7 | . . . o o o x .
 8 | . . . . o x . .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x x o o o o o o
 4 | x . x x o x o o
 5 | . . o x o x x o
 6 | . . o o x x x x
 7 | . . . o o x x .
 8 | . . . . o x x .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | . . o x o x x o
 6 | . . o o x x x x
 7 | . . . o o x x .
 8 | . . . . o x x .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | . x x x o x x o
 6 | . . o o x x x x
 7 | . . . o o x x .
 8 | . . . . o x x .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | o o o o o x x o
 6 | . . o o x x x x
 7 | . . . o o x x .
 8 | . . . . o x x .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o x x o
 6 | x . o o x x x x
 7 | . . . o o x x .
 8 | . . . . o x x .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x . o o x x o o
 7 | . . . o o o o o
 8 | . . . . o x x .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x . o o x x o o
 7 | . . . o x o o o
 8 | . . . x x x x .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x . o o x x o o
 7 | . . . o x o o o
 8 | . . . x x x x .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x x x x x x o o
 7 | . . . o x o o o
 8 | . . . x x x x .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x o x x x x o o
 7 | o . . o x o o o
 8 | . . . x x x x .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x x x x x x o o
 7 | o . x x x o o o
 8 | . . . x x x x .
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x x x o x x o o
 7 | o . o x x o o o
 8 | . o . x x x x .
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x x x o x x o o
 7 | o . o x x o x o
 8 | . o . x x x x x
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x o o o x x o o
 7 | o o o x x o x o
 8 | . o . x x x x x
Player 2 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x o o o x x o o
 7 | x o o x x o x o
 8 | x o . x x x x x
Player 1 to move.

     a b c d e f g h
   +----------------
 1 | x o o o o o o o
 2 | x o o o o o o o
 3 | x o o o o o o o
 4 | x o o o o x o o
 5 | x o o o o o x o
 6 | x o o o o x o o
 7 | x o o o x o x o
 8 | x o o x x x x x
Player 2 to move.

