#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;
use Game::Merrills::Test::Position qw/position_of stream/;

sub dies(&) {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : ($@ || 'died');
}

# play($white, $black): a whole game between two bots. Every move chosen must
# be one of the game's own legal move objects; the count of those that were
# not comes back with the game.
sub play {
	my ($white, $black) = @_;
	my %bot = (white => $white, black => $black);
	my $game = Game::Merrills->new;
	my $strangers = 0;
	while ($game->status eq 'active' && $game->ply < 3000) {
		my $move = $bot{ $game->turn }->choose($game);
		$strangers++ unless defined $move && grep { $_ == $move } @{ $game->legal_moves };
		my $played = $game->move($move);
		$strangers++ if ref $played eq 'Game::Merrills::Error';
		last if $strangers;
	}
	return ($game, $strangers);
}

subtest 'the levels' => sub {
	is_deeply([ Game::Merrills::Bot->levels ], [ 1 .. 5 ], 'one to five, weakest first');
	my ($depth, $nodes) = (0, 0);
	for my $level (Game::Merrills::Bot->levels) {
		my $setting = Game::Merrills::Bot->setting_for($level);
		cmp_ok($setting->{depth}, '>', $depth, "level $level looks further than the one below");
		cmp_ok($setting->{nodes}, '>', $nodes, "and at more positions");
		($depth, $nodes) = @{$setting}{qw/depth nodes/};
		is(Game::Merrills::Bot->new(level => $level)->level, $level, "level $level can be made");
	}
	ok(Game::Merrills::Bot->setting_for(1)->{jitter}, 'level 1 is varied by its seed');
	ok(!Game::Merrills::Bot->setting_for(3)->{jitter}, 'level 3 is not');
	my $setting = Game::Merrills::Bot->setting_for(3);
	$setting->{nodes} = 1;
	isnt(Game::Merrills::Bot->setting_for(3)->{nodes}, 1, 'setting_for hands out a copy');

	is(Game::Merrills::Bot->new->level, 3, 'the default is 3');
	is(Game::Merrills::Bot->new->seed, 0, 'with seed 0');
	for my $bad (0, 6, -1) {
		like(dies { Game::Merrills::Bot->new(level => $bad) }, qr/^level must be 1 \.\. 5, got '$bad'/,
			"level $bad cannot be made");
		like(dies { Game::Merrills::Bot->setting_for($bad) }, qr/^level must be 1 \.\. 5, got '$bad'/,
			"and has no setting");
	}
	like(dies { Game::Merrills::Bot->setting_for(undef) }, qr/^level must be 1 \.\. 5, got undef/,
		'nor has no level at all');
};

subtest 'levels 1 and 2: whole games, every move legal, every game ends' => sub {
	for my $run ([ 1, 20 ], [ 2, 4 ]) {
		my ($level, $games) = @{$run};
		my ($strangers, $plies, %ended) = (0, 0);
		for my $seed (1 .. $games) {
			my ($game, $bad) = play(
				Game::Merrills::Bot->new(level => $level, seed => $seed),
				Game::Merrills::Bot->new(level => $level, seed => 100 + $seed),
			);
			$strangers += $bad;
			$plies += $game->ply;
			$ended{ $game->result ? $game->result->reason : 'UNFINISHED' }++;
		}
		is($strangers, 0, "level $level: every move chosen was one the game offered");
		is($ended{UNFINISHED} || 0, 0, "level $level: all $games games ended");
		cmp_ok($plies, '>', $games * 18, "level $level: and went past placing, $plies plies in all");
		note "level $level ended by: " . join ', ', map { "$_ $ended{$_}" } sort keys %ended;
	}
};

subtest 'level 3: a game against level 2, each way round' => sub {
	my ($strangers, $unfinished, $games) = (0, 0, 0);
	for my $pair ([ 3, 2, 9 ], [ 2, 3, 10 ]) {
		my ($white, $black, $seed) = @{$pair};
		my ($game, $bad) = play(
			Game::Merrills::Bot->new(level => $white, seed => $seed),
			Game::Merrills::Bot->new(level => $black, seed => $seed + 50),
		);
		$games++;
		$strangers += $bad;
		$unfinished++ unless $game->result;
	}
	is($games, 2, 'two games');
	is($strangers, 0, 'every move chosen was one the game offered');
	is($unfinished, 0, 'and every game ended');
};

subtest 'a finished game, and a game with no choice' => sub {
	my $bot = Game::Merrills::Bot->new(level => 2);
	my $over = Game::Merrills->new;
	$over->resign;
	is($bot->choose($over), undef, 'nothing is chosen in a finished game');

	my $forced = Game::Merrills->new(position => position_of(
		white => [qw/a7 g7 g1 c3/], black => [qw/d7 g4 d1 c4 d3/],
	));
	is(scalar @{ $forced->legal_moves }, 1, 'white has one move');
	my $move = $bot->choose($forced);
	is($move, $forced->legal_moves->[0], 'and it is chosen');
	ok($bot->last_search->{forced}, 'last_search says it was forced');
	is($bot->last_search->{nodes}, 0, 'and that nothing was looked at');
	is($bot->last_search->{score}, undef, 'so it has no score');
	is_deeply($bot->last_search->{pv}, [ $move->notation ], 'and the line is the move alone');
};

subtest 'levels 4 and 5 choose a legal move too' => sub {
	plan skip_all => 'slow: set AUTHOR_TESTING to run the two deepest levels'
		unless $ENV{AUTHOR_TESTING};
	my $next = stream(45);
	for my $level (4, 5) {
		for my $stop (9, 26) {
			my $game = Game::Merrills->new;
			while ($game->ply < $stop) {
				my $legal = $game->legal_moves;
				$game->move($legal->[ $next->(scalar @{$legal}) ]);
			}
			my $bot = Game::Merrills::Bot->new(level => $level);
			my $move = $bot->choose($game);
			ok(scalar(grep { $_ == $move } @{ $game->legal_moves }),
				"level $level at ply $stop chose " . $move->notation . ', which is legal');
			cmp_ok($bot->last_search->{nodes}, '<=', Game::Merrills::Bot->setting_for($level)->{nodes},
				'within its number of positions');
		}
	}
};

done_testing;
