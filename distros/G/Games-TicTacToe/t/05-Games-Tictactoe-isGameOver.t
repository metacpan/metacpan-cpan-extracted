#!perl

use 5.006;
use strict; use warnings;
use Test::Warn;
use Games::TicTacToe;
use Test::More tests => 1;

warning_is { eval { Games::TicTacToe->new()->isGameOver(); } } "WARNING: No player found to play the TicTacToe game.";
