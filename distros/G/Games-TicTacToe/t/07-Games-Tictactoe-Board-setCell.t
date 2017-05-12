#!perl

use 5.006;
use strict; use warnings;
use Games::TicTacToe::Board;
use Test::More tests => 4;

my $board = Games::TicTacToe::Board->new();

eval { $board->setCell(); };
like($@, qr/ERROR: Missing cell index for TicTacToe Board./);

eval { $board->setCell(1); };
like($@, qr/ERROR: Missing symbol for TicTacToe Board./);

eval { $board->setCell(10, 'X'); };
like($@, qr/ERROR: Invalid cell index value for TicTacToe Board./);

eval { $board->setCell(1, 'M'); };
like($@, qr/ERROR: Invalid symbol for TicTacToe Board./);
