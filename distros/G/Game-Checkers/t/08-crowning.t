#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;

sub notations { [map { $_->notation } @{$_[0]->legal_moves}] }

subtest 'a crown ends the turn' => sub {
	plan tests => 5;
	# 22 takes 26 and lands on 31, which crowns it. As a king it could go on to
	# take 27, and the rule is that it may not: the turn ends with the crown.
	my $game = Game::Checkers->new(fen => 'B:W21,26,27:B22');
	is_deeply notations($game), ['22x31'],
		'the sequence stops at the crowning square';

	my $move = $game->move('22x31');
	ok $move->promoted, 'the move crowned the man';
	ok !$move->king, 'which it could not have done had it been a king already';
	is $game->board->at(31), Game::Checkers::Board::BLACK_KING, 'a king now stands on 31';
	is $game->turn, 'white', 'and it is the other side to move';
};

subtest 'the new king jumps on its next turn' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new(fen => 'B:W21,26,27:B22');
	$game->move('22x31');
	$game->move('21-17');

	ok $game->must_capture, 'the king it just made must now take';
	is_deeply notations($game), ['31x24'], 'backwards over 27, which a man could not do';
	is $game->move('31x24')->king, 1, 'and the mover was a king';
};

subtest 'undo takes the crown back off' => sub {
	plan tests => 4;
	my $game = Game::Checkers->new(fen => 'B:W21,26,27:B22');
	my $before = $game->to_fen;

	$game->move('22x31');
	my $undone = $game->undo;

	is $undone->notation, '22x31', 'the move comes back';
	is $game->to_fen, $before, 'and so does the position, to the letter';
	is $game->board->at(22), Game::Checkers::Board::BLACK_MAN, 'a man again, not a king';
	is $game->board->at(26), Game::Checkers::Board::WHITE_MAN, 'with the piece it took';
};

subtest 'a simple move crowns too' => sub {
	plan tests => 2;
	my $game = Game::Checkers->new(fen => 'W:W5:BK29');
	my $move = $game->move('5-1');
	ok $move->promoted, 'white crowns on the first row';
	is $game->board->at(1), Game::Checkers::Board::WHITE_KING, 'a white king';
};

done_testing;
