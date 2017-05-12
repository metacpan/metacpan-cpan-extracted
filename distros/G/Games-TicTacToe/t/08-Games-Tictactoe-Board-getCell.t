#!perl

use 5.006;
use strict; use warnings;
use Games::TicTacToe::Board;
use Test::More tests => 2;

my $board = Games::TicTacToe::Board->new();

eval { $board->getCell(); };
like($@, qr/ERROR: Missing cell index for TicTacToe Board./);

eval { $board->getCell(10); };
like($@, qr/ERROR: Invalid index value for TicTacToe Board./);
