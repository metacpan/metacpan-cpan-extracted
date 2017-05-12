use Test::More 'no_plan';
use Games::Board::Grid;

use strict;
use warnings;

my $board = Games::Board::Grid->new(size => 8);

isa_ok($board, 'Games::Board::Grid');

is($board->space('3 2')->dir_id([ 1,0]), '4 2',   "up a file from d3");
is($board->space('3 2')->dir_id([ 0,1]), '3 3',   "up a rank from d3");
is($board->space('3 2')->dir_id([-1,0]), '2 2', "down a file from d3");
is($board->space('3 2')->dir_id([0,-1]), '3 1', "down a rank from d3");

is($board->space('0 3')->dir_id([ 1,0]), '1 3',   "up a file from a4");
is($board->space('0 3')->dir_id([ 0,1]), '0 4',   "up a rank from a4");
is($board->space('0 3')->dir_id([-1,0]), undef, "down a file from a4");
is($board->space('0 3')->dir_id([0,-1]), '0 2', "down a rank from a4");

is($board->space('2 0')->dir_id([ 1,0]), '3 0',   "up a file from c1");
is($board->space('2 0')->dir_id([ 0,1]), '2 1',   "up a rank from c1");
is($board->space('2 0')->dir_id([-1,0]), '1 0', "down a file from c1");
is($board->space('2 0')->dir_id([0,-1]), undef, "down a rank from c1");

is($board->space('7 0')->dir_id([ 1,0]), undef,   "up a file from h1");
is($board->space('7 0')->dir_id([ 0,1]), '7 1',   "up a rank from h1");
is($board->space('7 0')->dir_id([-1,0]), '6 0', "down a file from h1");
is($board->space('7 0')->dir_id([0,-1]), undef, "down a rank from h1");

is($board->space('7 7')->dir_id([ 1,0]), undef,   "up a file from h8");
is($board->space('7 7')->dir_id([ 0,1]), undef,   "up a rank from h8");
is($board->space('7 7')->dir_id([-1,0]), '6 7', "down a file from h8");
is($board->space('7 7')->dir_id([0,-1]), '7 6', "down a rank from h8");

my $rook = $board->add_piece(id => 'KR');

isa_ok($rook, 'Games::Board::Piece');
is($rook->current_space_id, undef, "rook isn't on the board");
$rook->move(to => $board->space('1 1'));
is($rook->current_space_id, '1 1', "rook is at b2");
$rook->move(dir => [2,1]);
is($rook->current_space_id, '3 2', "rook is at d3");
