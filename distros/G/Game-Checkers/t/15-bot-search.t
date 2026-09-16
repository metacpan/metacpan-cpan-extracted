#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;
use Game::Checkers::Bot;

subtest 'the budget is in nodes and it holds' => sub {
	plan tests => 6;
	my $game = Game::Checkers->new;
	for my $level (1 .. 3) {
		my $bot = Game::Checkers::Bot->new(level => $level);
		$bot->choose($game);
		my $search = $bot->last_search;
		cmp_ok $search->{nodes}, '<=', $Game::Checkers::Bot::LEVEL{$level}{nodes},
			"level $level stayed inside its node budget";
		cmp_ok $search->{depth}, '>=', 1,
			"level $level finished at least one iteration";
	}
};

subtest 'what last_search says' => sub {
	plan tests => 5;
	my $game = Game::Checkers->new;
	my $bot = Game::Checkers::Bot->new(level => 3);
	my $move = $bot->choose($game);
	my $search = $bot->last_search;

	is $search->{move}, $move->notation, 'the move it settled on';
	ok !$search->{forced}, 'which it had to search for';
	ok defined $search->{score}, 'a score';
	cmp_ok scalar @{$search->{pv}}, '>=', 2, 'and a line, not just the move';
	is $search->{pv}[0], $move->notation, 'starting with the move';
};

subtest 'the principal variation is playable' => sub {
	plan tests => 1;
	my $game = Game::Checkers->new;
	my $bot = Game::Checkers::Bot->new(level => 3);
	$bot->choose($game);

	my $played = 0;
	my $replay = $game->clone;
	for my $notation (@{$bot->last_search->{pv}}) {
		my $move = $replay->move($notation);
		last if ref $move eq 'Game::Checkers::Error';
		$played++;
	}
	is $played, scalar @{$bot->last_search->{pv}},
		'every move in the line can actually be played in turn';
};

subtest 'the transposition table is an optimisation, not an opinion' => sub {
	plan tests => 4;
	my @position = (
		'B:W16,19,22,24:BK15',
		'B:W21,23:B5,9,13',
		'B:W28:BK19,15',
		'B:W5:BK6',
	);
	for my $fen (@position) {
		my $game = Game::Checkers->new(fen => $fen);
		my $with = Game::Checkers::Bot->new(level => 3);
		my $without = Game::Checkers::Bot->new(level => 3, transposition => 0);
		is $with->choose($game)->notation, $without->choose($game)->notation,
			"the table changes nothing in $fen";
	}
};

done_testing;
