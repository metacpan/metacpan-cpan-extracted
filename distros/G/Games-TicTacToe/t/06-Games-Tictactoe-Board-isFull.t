#!perl

use 5.006;
use strict; use warnings;
use Games::TicTacToe::Board;
use Test::More tests => 1;

is(Games::TicTacToe::Board->new()->isFull(), 0);
