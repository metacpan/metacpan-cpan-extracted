#!perl

# The bot's contract. Nothing here tests how WELL it plays: that is
# xt/bot-ladder.t, and it is a release test because it takes minutes.
#
# THE BUDGET ASSERTION IS THE ONE THAT MATTERS. A sibling distribution's bot
# overran its node budget fourfold and nothing noticed until somebody asserted
# the ceiling, so the ceiling is asserted here.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Bot;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

subtest 'what a bot will and will not be' => sub {
	is_deeply([ Game::Go::Bot->levels ], [ 1 .. 5 ], 'five levels');
	is(Game::Go::Bot->new->level, 3, 'three by default');

	for my $bad (0, 6, -1) {
		ok(!eval { Game::Go::Bot->new(level => $bad); 1 }, "level $bad is refused");
	}
	for my $ok (1 .. 5) {
		ok(eval { Game::Go::Bot->new(level => $ok); 1 }, "level $ok is fine");
	}
	done_testing();
};

subtest 'the budget is playouts, per size, and it is a ceiling' => sub {
	# PER SIZE, because a playout is not the same work on 81 points as on 361.
	for my $level (1 .. 5) {
		my $bot = Game::Go::Bot->new(level => $level);
		my ($nine, $thirteen, $nineteen) =
			map { $bot->budget($_) } (9, 13, 19);

		cmp_ok($nine, '>', 0, "level $level: 9x9 has a budget ($nine)");
		cmp_ok($nine, '>=', $thirteen, "level $level: and 13x13 no more than it ($thirteen)");
		cmp_ok($thirteen, '>=', $nineteen, "level $level: and 19x19 least of all ($nineteen)");
	}

	# Rising with the level, or the levels would not be levels.
	for my $size (9, 13, 19) {
		my @b = map { Game::Go::Bot->new(level => $_)->budget($size) } 1 .. 5;
		is_deeply([ sort { $a <=> $b } @b ], \@b, "size $size: the budgets rise with the level");
		cmp_ok($b[4], '>', $b[0] * 2, "size $size: and the top rung is well above the bottom");
	}

	# THE CEILING, ASSERTED. last_search reports what was actually run, and it
	# must never exceed what was asked for.
	for my $level (1, 3, 5) {
		my $bot = Game::Go::Bot->new(level => $level, seed => 'c');
		my $g = Game::Go->new(size => 9);
		$bot->choose($g, $B);
		my $ls = $bot->last_search;
		is($ls->{playouts}, $bot->budget(9), "level $level: ran exactly its budget, not more");
		is($ls->{level}, $level, "level $level: and reports the level");
		is($ls->{size}, 9, 'and the size');
	}
	done_testing();
};

subtest 'undef where the bot has nothing to say' => sub {
	my $bot = Game::Go::Bot->new(level => 1, seed => 'u');
	my $g = Game::Go->new(size => 9);

	# UNDEF AND NOT AN ERROR, because the site's bot driver breaks its loop on
	# undef and a refused move would strand the game instead.
	is($bot->choose($g, $W), undef, 'out of turn');
	is($bot->choose($g, Game::Go::EMPTY), undef, 'a colour that is not a player');

	$g->resign($W);
	is($bot->choose($g, $B), undef, 'after the game has ended');

	my $t = Game::Go->new(size => 9);
	$t->timeout($B);
	is($bot->choose($t, $W), undef, 'after a timeout');
	done_testing();
};

subtest 'it always returns a legal move' => sub {
	# Over a whole game, every move the bot offers is accepted. A bot that
	# offered a refused move would strand a game on the site.
	my $g = Game::Go->new(size => 9, seed => 'L' x 32);
	my %bot = (
		$B => Game::Go::Bot->new(level => 1, seed => 'b'),
		$W => Game::Go::Bot->new(level => 1, seed => 'w'),
	);

	my ($moves, $refusals, $passes) = (0, 0, 0);
	while ($g->status eq 'active' && $moves < 400) {
		my ($who) = $g->waiting_on;
		last unless defined $who;
		my $m = $bot{$who}->choose($g, $who);
		last unless $m;

		my $out =
			  $m->kind eq 'play'    ? $g->play($who, $m->point)
			: $m->kind eq 'pass'    ? $g->pass($who)
			: $m->kind eq 'mark'    ? $g->mark($who, $m->point)
			: $m->kind eq 'done'    ? $g->done($who)
			: $m->kind eq 'accept'  ? $g->accept($who)
			: $m->kind eq 'dispute' ? $g->dispute($who)
			: undef;

		$refusals++ if ref $out eq 'Game::Go::Error';
		$passes++ if $m->kind eq 'pass';
		$moves++;
	}

	is($refusals, 0, 'not one move was refused');
	cmp_ok($moves, '>', 20, "the game ran $moves moves, so it was really played");
	is($g->status, 'finished', 'and it finished');

	# It reached a score rather than stranding, which means the bot played the
	# confirmation phase too.
	is($g->result, 'score', 'by a score');
	ok(defined $g->scored_by, 'and it says how it was scored');
	done_testing();
};

subtest 'last_search says what it thought' => sub {
	my $bot = Game::Go::Bot->new(level => 3, seed => 'ls');
	is($bot->last_search, undef, 'nothing before the first search');

	my $g = Game::Go->new(size => 9);
	$bot->choose($g, $B);
	my $ls = $bot->last_search;

	cmp_ok($ls->{playouts}, '>', 0, 'playouts');
	cmp_ok($ls->{visits}, '>', 0, 'the chosen move was visited');
	cmp_ok($ls->{win_permille}, '>=', 0, 'with a win rate');
	cmp_ok($ls->{win_permille}, '<=', 1000, 'in permille');
	cmp_ok($ls->{roots}, '>', 1, 'over more than one root move');
	cmp_ok($ls->{moves}, '>', 0, 'and the playouts played moves');
	is($ls->{capped}, 0, 'with none of them hitting the move cap');

	# THE VISITS ARE THE THING TO LOOK AT. A move chosen on one visit is a move
	# chosen by a coin flip, and the search cuts its root set down rather than
	# let that happen: see the note in go_search.c.
	cmp_ok($ls->{visits}, '>=', 8, 'the chosen move had enough samples to mean something');
	done_testing();
};

subtest 'every size and every level produces a move' => sub {
	# What t/70-bot-levels.t demands of every game on the site: every rung of
	# every bag plays a move.
	for my $size (9, 13, 19) {
		for my $level (1 .. 5) {
			my $g = Game::Go->new(size => $size);
			my $m = Game::Go::Bot->new(level => $level, seed => "s$size$level")
				->choose($g, $B);
			ok($m, "size $size level $level: a move");
			is($m->kind, 'play', "size $size level $level: a play rather than a pass");
			ok($g->play($B, $m->point)->isa('Game::Go::Move'),
				"size $size level $level: which the rules accept");
		}
	}
	done_testing();
};

done_testing();
