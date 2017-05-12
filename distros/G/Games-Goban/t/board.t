use Test::More 'no_plan';

use strict;
use warnings;

use_ok('Games::Goban::Board');

{ # skip_i == 0
  my $board = Games::Goban::Board->new(size => 19);

  isa_ok($board, 'Games::Goban::Board');
  isa_ok($board, 'Games::Board::Grid');
  isa_ok($board, 'Games::Board');

  is( $board->index2id([ 0, 0]), 'aa', "0,0 is 'aa'");
  is( $board->index2id([ 5, 9]), 'fj', "5,9 is 'fj'");
  is( $board->index2id([18,18]), 'ss', "18,18 is 'ss'");

  ok( eq_array( $board->id2index('aa'), [ 0, 0] ), "space 'aa' is 0,0");
  ok( eq_array( $board->id2index('fj'), [ 5, 9] ), "space 'fj' is 5,9");
  ok( eq_array( $board->id2index('ss'), [18,18] ), "space 'ss' is 18,18");

  my $stone = $board->add_piece( color => 'b', move  => 2 );

  isa_ok($stone, 'Games::Goban::Piece');
  is($stone->color,  'b', "correct color");
  is($stone->colour, 'b', "correct colour");
  is($stone->moved_on, 2, "moved on second move");
  is($stone->position, undef, "not yet on board");

  $stone->move(to => $board->space('cd'));

  is($stone->position, 'cd', "moved to position cd");
}

{ # skip_i == 1
  my $board = Games::Goban::Board->new(size => 19, skip_i => 1);

  isa_ok($board, 'Games::Goban::Board');
  isa_ok($board, 'Games::Board::Grid');
  isa_ok($board, 'Games::Board');

  is( $board->index2id([ 0, 0]), 'aa', "0,0 is 'aa'");
  is( $board->index2id([ 5, 9]), 'fk', "5,9 is 'fk'");
  is( $board->index2id([18,18]), 'tt', "18,18 is 'tt'");

  ok( eq_array( $board->id2index('aa'), [ 0, 0] ), "space 'aa' is 0,0");
  ok( eq_array( $board->id2index('fk'), [ 5, 9] ), "space 'fk' is 5,9");
  ok( eq_array( $board->id2index('ss'), [17,17] ), "space 'ss' is 17,17");
  ok( eq_array( $board->id2index('tt'), [18,18] ), "space 'tt' is 18,18");

  my $stone = $board->add_piece( color => 'b', move  => 2 );

  isa_ok($stone, 'Games::Goban::Piece');
  is($stone->color,  'b', "correct color");
  is($stone->colour, 'b', "correct colour");
  is($stone->moved_on, 2, "moved on second move");
  is($stone->position, undef, "not yet on board");

  $stone->move(to => $board->space('cd'));

  is($stone->position, 'cd', "moved to position cd");
}
