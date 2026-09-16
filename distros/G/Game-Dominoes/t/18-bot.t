#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Bot;
use Game::Dominoes::Boneyard;
use Game::Dominoes::Hand;
use Game::Dominoes::Tile;

plan tests => 8;

sub tile { Game::Dominoes::Tile->of(@_) }
sub bot { Game::Dominoes::Bot->new(@_) }
sub game { Game::Dominoes->new(seed => 'a' x 32, @_) }

sub name { my ($m) = @_; return $m ? $m->{tile}->stringify . '@' . $m->{arm} : '-' }

subtest 'the level table is a closed set' => sub {
	plan tests => 5;

	my $levels = Game::Dominoes::Bot->levels;
	is_deeply [ sort { $a <=> $b } keys %$levels ], [ 1 .. 5 ],
		'there are five levels and no others';

	ok !eval { bot(level => 0); 1 }, 'level 0 dies';
	ok !eval { bot(level => 6); 1 }, 'level 6 dies';

	is $levels->{1}{worlds}, 0, 'level 1 samples no worlds, so it is pure greed';
	cmp_ok $levels->{5}{worlds}, '>', $levels->{3}{worlds},
		'and a higher level samples more';
};

subtest 'every play it returns is one the game would accept' => sub {
	plan tests => 3;

	for my $players (2, 3, 4) {
		my $g = game(players => $players);
		my $b = bot(level => 2, seed => 11);
		my ($bad, $n) = (0, 0);

		while ($g->status eq 'active' && $n++ < 2000) {
			my $seat = $g->turn;
			my $move = $b->choose($g, $seat) or last;

			my $legal = $g->legal($seat);
			$bad++ unless grep {
				$_->{tile}->id == $move->{tile}->id && $_->{arm} eq $move->{arm}
			} @$legal;

			my $out = $g->play($seat, $move);
			$bad++ if ref $out eq 'Game::Dominoes::Error';
		}
		is $bad, 0, "$players players: every play was legal and accepted";
	}
};

subtest 'the same view, level and seed choose the same play' => sub {
	plan tests => 2;

	# A game log that cannot be replayed is not a game log, so this is the
	# property the whole design is bent around.
	my $g = game();
	my $one = bot(level => 3, seed => 99)->choose($g, $g->turn);
	my $two = bot(level => 3, seed => 99)->choose($g, $g->turn);
	is name($one), name($two), 'two bots with the same seed agree';

	my $again = bot(level => 3, seed => 99);
	is name($again->choose($g, $g->turn)), name($again->choose($g, $g->turn)),
		'and one bot asked twice does not wander';
};

subtest 'a different bot seed is allowed to differ' => sub {
	plan tests => 1;

	# The sampler is driven by the bot own seed, so two differently seeded
	# bots explore different worlds. They will often agree anyway, because
	# many positions have an obvious play, so this looks across a run rather
	# than asserting a difference at any one position.
	my $differ = 0;
	for my $n (1 .. 40) {
		my $g = Game::Dominoes->new(seed => sprintf('%032d', $n), players => 3);
		my $a = bot(level => 3, seed => 1)->choose($g, $g->turn);
		my $b = bot(level => 3, seed => 2)->choose($g, $g->turn);
		$differ++ if name($a) ne name($b);
	}
	cmp_ok $differ, '>', 0,
		'across forty positions the two seeds disagreed at least once';
};

subtest 'the sampler honours a pass, which is the deduction that matters' => sub {
	plan tests => 3;

	# A seat that passes holds nothing matching the ends that were open then,
	# and because a pass only happens once the boneyard is dry, that stays
	# true for the rest of the hand.
	my $g = game(players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(6, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3), tile(2, 2) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => []));
	$g->turn(1);
	$g->history([]);
	$g->play(1, '6-4@L');

	# Seat 2 cannot match a six or a four, so it passes and says so.
	my ($pass) = grep { $_->{kind} eq 'pass' } @{ $g->history };
	ok $pass, 'seat 2 passed';
	is_deeply $pass->{cannot}, [ 4, 6 ],
		'and the log records which faces it cannot hold';

	my $view = $g->view(1);
	is_deeply $view->{deductions}{2}, { 4 => 1, 6 => 1 },
		'which reaches the view as a deduction anybody watching could make';
};

subtest 'a sampled world never contradicts a deduction' => sub {
	plan tests => 2;

	# Reaching into the sampler on purpose: this is the constraint that makes
	# the bot worth playing, and nothing visible from outside would show it
	# had been dropped.
	my $g = game(players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(6, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(
		tiles => [ tile(3, 3), tile(2, 2), tile(1, 1) ]
	);
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => []));
	$g->turn(1);
	$g->play(1, '6-4@L');

	my $view = $g->view(1);
	my $b = bot(level => 3, seed => 5);
	my $next = $b->_stream('test');

	my ($worlds, $violations) = (0, 0);
	for (1 .. 200) {
		my $world = $b->_sample($view, $next);
		$worlds++;
		for my $tile (@{ $world->{hands}{2} }) {
			$violations++ if $tile->has_face(6) || $tile->has_face(4);
		}
	}

	is $worlds, 200, 'the sampler produced a world every time it was asked';
	is $violations, 0,
		'and never dealt seat 2 a tile it had shown it could not hold';
};

subtest 'it respects a forced draw' => sub {
	plan tests => 2;

	# A drawn playable tile must be the tile played, so the bot must not go
	# hunting through the rest of the hand for something better.
	my $g = game(players => 2);
	$g->hands->{1} = Game::Dominoes::Hand->new(tiles => [ tile(6, 4), tile(1, 1) ]);
	$g->hands->{2} = Game::Dominoes::Hand->new(tiles => [ tile(3, 3) ]);
	$g->boneyard(Game::Dominoes::Boneyard->new(tiles => [ tile(2, 2), tile(6, 5) ]));
	$g->turn(1);
	$g->play(1, '6-4@L');

	is $g->forced_tile->stringify, '6-5', 'seat 2 drew the 6-5 and is stuck with it';
	my $move = bot(level => 3, seed => 3)->choose($g, 2);
	is $move->{tile}->stringify, '6-5', 'and the bot plays it rather than choosing';
};

subtest 'last_search reports what the move cost' => sub {
	plan tests => 4;

	my $g = game();

	my $greedy = bot(level => 1, seed => 4);
	$greedy->choose($g, $g->turn);
	is $greedy->last_search->{worlds}, 0, 'level 1 sampled nothing';
	is $greedy->last_search->{level}, 1, 'and says so';

	my $searcher = bot(level => 3, seed => 4);
	$searcher->choose($g, $g->turn);
	cmp_ok $searcher->last_search->{worlds}, '>', 0, 'level 3 sampled worlds';
	cmp_ok $searcher->last_search->{considered}, '>', 1,
		'and had more than one play to weigh';
};
