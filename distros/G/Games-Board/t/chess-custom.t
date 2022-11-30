use Test::More 'no_plan';
use Games::Board::Grid;

use strict;
use warnings;

package Games::Board::Chess;
use base qw(Games::Board::Grid);

sub piececlass { 'Games::Board::Chess::Piece' }

sub new { my $self = shift; $self->SUPER::new(size => 8) }

sub id2index {
  shift;
  my $id = shift; 
  my @loc = split //, $id;
  
  $loc[0] =~ tr/[a-h]/[1-8]/;
  $_-- for @loc;
  \@loc;
}

sub index2id {
  shift;
  my $loc = shift;
  my @id = @$loc;
  
  $_++ for @id;
  $id[0] =~ tr/[1-8]/[a-h]/;
  "$id[0]$id[1]"
}

package Games::Board::Chess::Piece;
use base qw(Games::Board::Piece);

package main;

my $board = Games::Board::Chess->new;

isa_ok($board, 'Games::Board::Chess');

is($board->space('d3')->dir_id([ 1,0]),  'e3',   "up a file from d3");
is($board->space('d3')->dir_id([ 0,1]),  'd4',   "up a rank from d3");
is($board->space('d3')->dir_id([-1,0]),  'c3', "down a file from d3");
is($board->space('d3')->dir_id([0,-1]),  'd2', "down a rank from d3");

is($board->space('a4')->dir_id([ 1,0]),  'b4',   "up a file from a4");
is($board->space('a4')->dir_id([ 0,1]),  'a5',   "up a rank from a4");
is($board->space('a4')->dir_id([-1,0]), undef, "down a file from a4");
is($board->space('a4')->dir_id([0,-1]),  'a3', "down a rank from a4");

is($board->space('c1')->dir_id([ 1,0]),  'd1',   "up a file from c1");
is($board->space('c1')->dir_id([ 0,1]),  'c2',   "up a rank from c1");
is($board->space('c1')->dir_id([-1,0]),  'b1', "down a file from c1");
is($board->space('c1')->dir_id([0,-1]), undef, "down a rank from c1");

is($board->space('h1')->dir_id([ 1,0]), undef,   "up a file from h1");
is($board->space('h1')->dir_id([ 0,1]),  'h2',   "up a rank from h1");
is($board->space('h1')->dir_id([-1,0]),  'g1', "down a file from h1");
is($board->space('h1')->dir_id([0,-1]), undef, "down a rank from h1");

is($board->space('h8')->dir_id([ 1,0]), undef,   "up a file from h8");
is($board->space('h8')->dir_id([ 0,1]), undef,   "up a rank from h8");
is($board->space('h8')->dir_id([-1,0]),  'g8', "down a file from h8");
is($board->space('h8')->dir_id([0,-1]),  'h7', "down a rank from h8");

my $rook = $board->add_piece(id => 'KR');

isa_ok($rook, 'Games::Board::Chess::Piece');
isa_ok($rook, 'Games::Board::Piece');
is($rook->current_space_id, undef, "rook isn't on the board");
$rook->move(to => $board->space('b2'));
is($rook->current_space_id, 'b2', "rook is at b2");
$rook->move(dir => [2,1]);
is($rook->current_space_id, 'd3', "rook is at d3");

ok(!$board->space('b2')->contains($rook), "space b2 does not contain rook");
