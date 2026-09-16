#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;
use Game::Checkers::Bot;

# Every position here was worked out by hand first and then checked against the
# engine, never the other way round: a position the bot chose and we then
# blessed proves only that the bot agrees with itself.

subtest 'a two for one shot' => sub {
	plan tests => 4;
	# Black men on 5, 9 and 13 against White men on 21 and 23.
	# 13-17 offers the man: White must take, 21x14, and cannot continue past 14
	# because the man on 5 blocks the landing square behind 9. That leaves White
	# men on 14 and 23 exactly one diagonal apart, and 9x18x27 takes both.
	my $game = Game::Checkers->new(fen => 'B:W21,23:B5,9,13');
	is_deeply [map { $_->notation } @{$game->legal_moves}], [qw/9-14 13-17/],
		'two moves to choose between';

	my $bot = Game::Checkers::Bot->new(level => 3);
	my $move = $bot->choose($game);
	is $move->notation, '13-17', 'the bot gives the man up';
	cmp_ok $bot->last_search->{score}, '>', 5_000, 'and knows it is winning';

	$game->move($move);
	$game->move($game->legal_moves->[0]);
	$game->move('9x18x27');
	is $game->result->winner, 'black', 'the shot wins the game outright';
};

subtest 'the only move that keeps the king' => sub {
	plan tests => 2;
	# A lone Black king on 15 against four White men. 15-11 is taken by 16x7 and
	# 15-18 by 22x15; the retreat to 10 is the only square White cannot reach.
	my $game = Game::Checkers->new(fen => 'B:W16,19,22,24:BK15');
	is_deeply [map { $_->notation } @{$game->legal_moves}], [qw/15-10 15-11 15-18/],
		'three squares, two of them poisoned';

	my $move = Game::Checkers::Bot->new(level => 3)->choose($game);
	is $move->notation, '15-10', 'the bot retreats';
};

subtest 'a king and a man against a king' => sub {
	plan tests => 3;
	# 19-24 walks under the White king on 28, which takes it. The other three
	# moves are safe, and the ending is winning for Black.
	my $game = Game::Checkers->new(fen => 'B:W28:BK19,15');
	my $bot = Game::Checkers::Bot->new(level => 3);
	my $move = $bot->choose($game);
	isnt $move->notation, '19-24', 'the bot does not step in front of the king';

	cmp_ok $bot->last_search->{score}, '>', 0, 'it knows the ending is its own';

	$game->move($move);
	ok !$game->must_capture, 'and nothing is left hanging for White to take';
};

subtest 'a win by taking the last square away' => sub {
	plan tests => 3;
	# The White man on 5 has one move in the world, 5-1. A Black king on 6 can
	# stand on 1, and a man on 5 cannot jump off the top of the board.
	my $game = Game::Checkers->new(fen => 'B:W5:BK6');
	is_deeply [map { $_->notation } @{$game->legal_moves}], [qw/6-1 6-2 6-9 6-10/],
		'four moves, one of them is the game';

	my $move = Game::Checkers::Bot->new(level => 3)->choose($game);
	is $move->notation, '6-1', 'the bot blocks the square';

	$game->move($move);
	is $game->result->stringify, 'Black wins: White has no move', 'and that is that';
};

done_testing;
