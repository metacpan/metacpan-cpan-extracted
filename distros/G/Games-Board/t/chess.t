use Test::More 'no_plan';
use Games::Board;

use strict;
use warnings;

my $board = Games::Board->new;

for my $rank ('1' .. '8') {
  for my $file ('a' .. 'h') {
    my $dir = {};
    my $id  = $file . $rank;

    ($dir->{up_file}   = $id) =~ tr/a-g/b-h/ unless $file eq 'h';
    ($dir->{down_file} = $id) =~ tr/b-h/a-g/ unless $file eq 'a';
    $dir->{up_rank}   = $file . ($rank + 1) unless $rank == 8;
    $dir->{down_rank} = $file . ($rank - 1) unless $rank == 1;

    $board->add_space(id => $id, dir => $dir)
  }
}

for my $rank ('1' .. '8') {
  for my $file ('a' .. 'h') {
    my $id = $file . $rank;
    ok($board->space($id),          "$id: exists on the board");
    is($board->space($id)->id, $id, "$id: correct id");
  }
}

is($board->space('d3')->dir_id('up_file'),    'e3',   "up a file from d3");
is($board->space('d3')->dir_id('up_rank'),    'd4',   "up a rank from d3");
is($board->space('d3')->dir_id('down_file'),  'c3', "down a file from d3");
is($board->space('d3')->dir_id('down_rank'),  'd2', "down a rank from d3");

is($board->space('a4')->dir_id('up_file'),    'b4',   "up a file from a4");
is($board->space('a4')->dir_id('up_rank'),    'a5',   "up a rank from a4");
is($board->space('a4')->dir_id('down_file'), undef, "down a file from a4");
is($board->space('a4')->dir_id('down_rank'),  'a3', "down a rank from a4");

is($board->space('c1')->dir_id('up_file'),    'd1',   "up a file from c1");
is($board->space('c1')->dir_id('up_rank'),    'c2',   "up a rank from c1");
is($board->space('c1')->dir_id('down_file'),  'b1', "down a file from c1");
is($board->space('c1')->dir_id('down_rank'), undef, "down a rank from c1");

is($board->space('h1')->dir_id('up_file'),   undef,   "up a file from h1");
is($board->space('h1')->dir_id('up_rank'),    'h2',   "up a rank from h1");
is($board->space('h1')->dir_id('down_file'),  'g1', "down a file from h1");
is($board->space('h1')->dir_id('down_rank'), undef, "down a rank from h1");

is($board->space('h8')->dir_id('up_file'),   undef,   "up a file from h8");
is($board->space('h8')->dir_id('up_rank'),   undef,   "up a rank from h8");
is($board->space('h8')->dir_id('down_file'),  'g8', "down a file from h8");
is($board->space('h8')->dir_id('down_rank'),  'h7', "down a rank from h8");

my $rook = $board->add_piece(id => 'KR');

isa_ok($rook, 'Games::Board::Piece');
exit;
is($rook->current_space_id, undef, "rook isn't on the board");
$rook->move(to => $board->space('a1'));
is($rook->current_space_id, 'a1', "rook is at a1");
$rook->move(dir => 'up_rank');
$rook->move(dir => 'up_file');
$rook->move(dir => 'up_file');
is($rook->current_space_id, 'c2', "rook is at c2");
