#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers::Board;

subtest 'the opening position' => sub {
	plan tests => 35;
	my $board = Game::Checkers::Board->new;
	is $board->at($_), Game::Checkers::Board::BLACK_MAN, "a black man on $_"
		for 1 .. 12;
	is $board->at($_), Game::Checkers::Board::EMPTY, "nothing on $_"
		for 13 .. 20;
	is $board->at($_), Game::Checkers::Board::WHITE_MAN, "a white man on $_"
		for 21 .. 32;
	is_deeply $board->count('black'), { men => 12, kings => 0, total => 12 },
		'twelve black men';
	is_deeply $board->count('white'), { men => 12, kings => 0, total => 12 },
		'twelve white men';
	is_deeply $board->count, { men => 24, kings => 0, total => 24 },
		'twenty four pieces in all';
};

subtest 'pieces' => sub {
	plan tests => 10;
	my $board = Game::Checkers::Board->new(position => [
		(0) x 33
	]);
	$board->set(1, Game::Checkers::Board::BLACK_MAN);
	$board->set(2, Game::Checkers::Board::BLACK_KING);
	$board->set(31, Game::Checkers::Board::WHITE_MAN);
	$board->set(32, Game::Checkers::Board::WHITE_KING);

	is $board->piece(1)->stringify, 'b', 'a black man';
	is $board->piece(2)->stringify, 'B', 'a black king';
	is $board->piece(31)->stringify, 'w', 'a white man';
	is $board->piece(32)->stringify, 'W', 'a white king';
	is $board->piece(3), undef, 'nothing on an empty square';

	is $board->colour_at(2), 'black', 'colour_at';
	ok $board->king_at(2), 'king_at';
	ok !$board->king_at(1), 'a man is not a king';
	ok $board->occupied(1), 'occupied';
	ok $board->empty(3), 'empty';
};

subtest 'a piece knows its own encoding' => sub {
	plan tests => 4;
	my $board = Game::Checkers::Board->new;
	is $board->piece(1)->value, Game::Checkers::Board::BLACK_MAN, 'black man';
	is $board->piece(21)->value, Game::Checkers::Board::WHITE_MAN, 'white man';
	$board->set(5, Game::Checkers::Board::BLACK_KING);
	is $board->piece(5)->value, Game::Checkers::Board::BLACK_KING, 'black king';
	$board->set(6, Game::Checkers::Board::WHITE_KING);
	is $board->piece(6)->value, Game::Checkers::Board::WHITE_KING, 'white king';
};

subtest 'clone is deep' => sub {
	plan tests => 3;
	my $board = Game::Checkers::Board->new;
	my $copy = $board->clone;
	is_deeply $copy->position, $board->position, 'the same position';
	$copy->set(1, Game::Checkers::Board::EMPTY);
	is $board->at(1), Game::Checkers::Board::BLACK_MAN,
		'and mutating the copy leaves the original alone';
	isnt $copy->position, $board->position, 'two arrays, not one';
};

subtest 'a position is validated' => sub {
	plan tests => 4;
	ok !eval { Game::Checkers::Board->new(position => [(0) x 32]); 1 },
		'32 slots is not a position';
	ok !eval { Game::Checkers::Board->new(position => [(0) x 34]); 1 },
		'34 slots is not a position either';
	ok !eval { Game::Checkers::Board->new(position => [(0) x 32, 3]); 1 },
		'3 is not a piece';
	ok !eval { Game::Checkers::Board->new(position => [(0) x 32, undef]); 1 },
		'and neither is undef';
};

subtest 'FEN' => sub {
	plan tests => 5;
	my $board = Game::Checkers::Board->new;
	my $fen = $board->to_fen('black');
	is $fen,
		'B:W21,22,23,24,25,26,27,28,29,30,31,32:B1,2,3,4,5,6,7,8,9,10,11,12',
		'the opening position';

	my ($restored, $turn) = Game::Checkers::Board->from_fen($fen);
	is_deeply $restored->position, $board->position, 'and it comes back';
	is $turn, 'black', 'with the side to move';

	my $scalar = Game::Checkers::Board->from_fen($fen);
	isa_ok $scalar, 'Game::Checkers::Board';

	$board->set(1, Game::Checkers::Board::BLACK_KING);
	like $board->to_fen('white'), qr/^W:.*:BK1,/, 'a king is marked and White is to move';
};

done_testing;
