#!perl

use 5.006;
use strict; use warnings;
use Games::TicTacToe::Player;
use Test::More tests => 2;

eval { Games::TicTacToe::Player->new(type => 'Q'); };
like($@, qr/isa check for 'PlayerType' failed/);

eval { Games::TicTacToe::Player->new(symbol => 'R'); };
like($@, qr/isa check for 'symbol' failed/);
