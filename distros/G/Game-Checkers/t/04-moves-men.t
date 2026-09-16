#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;

sub notations { [map { $_->notation } @{$_[0]->legal_moves}] }

subtest 'the opening moves' => sub {
	plan tests => 4;
	my $game = Game::Checkers->new;
	is $game->turn, 'black', 'black moves first';
	is $game->status, 'active', 'and the game is on';
	is_deeply notations($game),
		[qw/9-13 9-14 10-14 10-15 11-15 11-16 12-16/],
		q|Black's seven opening moves, in order|;

	$game->move('11-15');
	is_deeply notations($game),
		[qw/21-17 22-17 22-18 23-18 23-19 24-19 24-20/],
		q|and White's seven|;
};

subtest 'a man only moves forward, one square, to an empty square' => sub {
	plan tests => 6;
	my $game = Game::Checkers->new(fen => 'B:W29:B15');
	is_deeply notations($game), [qw/15-18 15-19/], 'a man in the open has two moves';

	my $back = $game->move('15-11');
	ok $back->wrong_direction, 'backwards is refused';
	is $back->code, 'wrong_direction', 'and says so';

	ok $game->move('15-16')->not_legal, 'sideways is not a move';
	ok $game->move('15-24')->not_legal, 'and neither is two squares with nothing to jump';

	my $blocked = Game::Checkers->new(fen => 'B:W29:B15,19');
	ok $blocked->move('15-19')->occupied, 'a square of your own is in the way';
};

subtest 'a man on the edge' => sub {
	plan tests => 2;
	my $game = Game::Checkers->new(fen => 'B:W29:B12');
	is_deeply notations($game), ['12-16'], 'square 12 has one move';

	my $other = Game::Checkers->new(fen => 'B:W29:B13');
	is_deeply notations($other), ['13-17'], 'and so has square 13';
};

subtest 'a man that reaches the far row is crowned' => sub {
	plan tests => 3;
	my $game = Game::Checkers->new(fen => 'B:W21:B25');
	my $move = $game->move('25-29');
	ok $move->promoted, 'the move says it crowned';
	ok $game->board->king_at(29), 'and the board has a king';
	is $game->board->at(29), Game::Checkers::Board::BLACK_KING, 'a black one';
};

done_testing;
