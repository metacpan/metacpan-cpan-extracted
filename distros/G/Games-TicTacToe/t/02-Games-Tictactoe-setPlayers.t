#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use Test::Warn;
use Games::TicTacToe;
use Games::TicTacToe::Player;
use Test::More tests => 1;

my $player1   = Games::TicTacToe::Player->new(type => 'H', symbol => 'X');
my $player2   = Games::TicTacToe::Player->new(type => 'C', symbol => 'O');
my $tictactoe = Games::TicTacToe->new(players => [$player1, $player2]);

warning_is { eval { $tictactoe->setPlayers(); } } "WARNING: We already have 2 players to play the TicTacToe game.";
