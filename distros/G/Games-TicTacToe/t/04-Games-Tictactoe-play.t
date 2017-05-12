#!perl

use 5.006;
use strict; use warnings;
use Games::TicTacToe;
use Test::More tests => 1;

eval { Games::TicTacToe->new()->play(); };
like($@, qr/ERROR: Please add player before you start the game./);
