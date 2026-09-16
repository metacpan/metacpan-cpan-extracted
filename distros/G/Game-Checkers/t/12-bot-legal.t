#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Checkers;
use Game::Checkers::Bot;

subtest 'whatever the position, the move is one of the legal ones' => sub {
	plan tests => 3;
	my $positions = 0;
	my $legal = 0;
	my $identical = 0;

	# the positions come from games the bot plays against itself, which is the
	# cheapest way to reach a few hundred positions that are not all openings
	for my $seed (1 .. 6) {
		my $game = Game::Checkers->new;
		my %bot = (
			black => Game::Checkers::Bot->new(level => 2, seed => $seed),
			white => Game::Checkers::Bot->new(level => 2, seed => $seed + 100)
		);
		while ($game->status eq 'active' && $game->ply < 120) {
			my $move = $bot{$game->turn}->choose($game);
			$positions++;
			$legal++ if grep { $_->notation eq $move->notation } @{$game->legal_moves};
			$identical++ if grep { $_ == $move } @{$game->legal_moves};
			$game->move($move);
		}
	}

	cmp_ok $positions, '>=', 200, "$positions positions seen";
	is $legal, $positions, 'every move chosen was legal';
	is $identical, $positions,
		'and was the very object from the legal list, not a copy of it';
};

subtest 'the corners of choose' => sub {
	plan tests => 4;
	my $bot = Game::Checkers::Bot->new(level => 3);

	my $forced = Game::Checkers->new(fen => 'B:W29:B12');
	my $move = $bot->choose($forced);
	is $move->notation, '12-16', 'one legal move is returned without a search';
	ok $bot->last_search->{forced}, 'and says it did not search';
	is $bot->last_search->{nodes}, 0, 'no nodes spent on a move with no choice';

	my $over = Game::Checkers->new(fen => 'B:W15:B');
	is $bot->choose($over), undef, 'a finished game has no move to choose';
};

subtest 'every level plays' => sub {
	plan tests => 5;
	my $game = Game::Checkers->new(fen => 'B:W16,19,22,24:BK15');
	for my $level (1 .. 5) {
		my $bot = Game::Checkers::Bot->new(level => $level);
		# the position has three moves and a small tree, so even level 5 is
		# cheap here: the budget is what bounds it, not a clock
		ok $bot->choose($game), "level $level returns a move";
	}
};

done_testing;
