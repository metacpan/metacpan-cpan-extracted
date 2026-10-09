#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;
use Game::Merrills::Test::Position qw/stream/;

# record($level, $white_seed, $black_seed, $plies): the game two bots play, as
# text, stopped after so many plies.
sub record {
	my ($level, $white_seed, $black_seed, $plies) = @_;
	my %bot = (
		white => Game::Merrills::Bot->new(level => $level, seed => $white_seed),
		black => Game::Merrills::Bot->new(level => $level, seed => $black_seed),
	);
	my $game = Game::Merrills->new;
	while ($game->status eq 'active' && $game->ply < $plies) {
		$game->move($bot{ $game->turn }->choose($game));
	}
	return $game->to_text;
}

subtest 'the same seeds play the same game' => sub {
	for my $level (1, 2) {
		my $first = record($level, 11, 12, 30);
		is(record($level, 11, 12, 30), $first, "level $level, played twice, is one game");
		cmp_ok(length $first, '>', 100, 'and it is a game, not an empty string');
	}
};

subtest 'at levels 1 and 2 the seed is live' => sub {
	for my $level (1, 2) {
		my %games = map { record($level, $_, $_ + 1, 16) => 1 } 1, 21, 41, 61, 81, 101;
		cmp_ok(scalar keys %games, '>=', 5, "level $level: six seeds, " . keys(%games) . ' different games');
	}
};

subtest 'from level 3 the seed is dead' => sub {
	my $first = record(3, 1, 2, 20);
	is(record(3, 900, 901, 20), $first, 'level 3 plays one game whatever the seeds');
	cmp_ok(length $first, '>', 60, 'and it is a game');
};

subtest 'choosing leaves the game exactly as it was' => sub {
	my $next = stream(1313);
	my $checked = 0;
	for my $level (1, 2, 3) {
		for my $stop (0, 7, 17, 18, 31, 44) {
			my $game = Game::Merrills->new;
			while ($game->status eq 'active' && $game->ply < $stop) {
				my $legal = $game->legal_moves;
				$game->move($legal->[ $next->(scalar @{$legal}) ]);
			}
			next unless $game->status eq 'active';
			$checked++;

			my $legal = $game->legal_moves;
			my @before = ($game->to_position, $game->ply, $game->no_mill, $game->turn,
				join(',', map { "$_=" . $game->repetition->{$_} } sort keys %{ $game->repetition }));
			my $bot = Game::Merrills::Bot->new(level => $level, seed => $stop);
			my $move = $bot->choose($game);
			my @after = ($game->to_position, $game->ply, $game->no_mill, $game->turn,
				join(',', map { "$_=" . $game->repetition->{$_} } sort keys %{ $game->repetition }));

			is_deeply(\@after, \@before, "level $level at ply $stop: the game is untouched");
			is($game->legal_moves, $legal, 'down to the very list of legal moves');
			ok(scalar(grep { $_ == $move } @{$legal}), 'the move chosen is an object out of that list');
			is($bot->choose($game), $move, 'and asked again, the bot chooses it again');
			is($bot->last_search->{move}, $move->notation, 'last_search names it');
		}
	}
	cmp_ok($checked, '>=', 15, "$checked positions");
};

subtest 'what last_search says' => sub {
	my $game = Game::Merrills->new;
	$game->move($_) for qw/d2 f4 d6 b4/;
	my $bot = Game::Merrills::Bot->new(level => 3);
	is($bot->last_search, undef, 'nothing before the first choice');
	my $move = $bot->choose($game);
	my $search = $bot->last_search;
	is_deeply([ sort keys %{$search} ], [qw/depth forced move nodes pv score/], 'six things');
	ok(!$search->{forced}, 'the move was not forced');
	cmp_ok($search->{depth}, '>=', 1, "it finished a look $search->{depth} deep");
	cmp_ok($search->{depth}, '<=', Game::Merrills::Bot->setting_for(3)->{depth}, 'no deeper than its level allows');
	cmp_ok($search->{nodes}, '>', 0, "at $search->{nodes} positions");
	cmp_ok($search->{nodes}, '<=', Game::Merrills::Bot->setting_for(3)->{nodes}, 'no more than its level allows');
	like($search->{score}, qr/^-?[0-9]+$/, 'the score is a whole number');
	is($search->{pv}[0], $move->notation, 'the expected line begins with the move chosen');

	my $replay = $game->clone;
	my $refused = 0;
	for my $written (@{ $search->{pv} }) {
		$refused++ if ref $replay->move($written) eq 'Game::Merrills::Error';
	}
	is($refused, 0, 'and every move of the line is legal when its turn comes: ' . join ' ', @{ $search->{pv} });
};

done_testing;
