#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Bot;
use Game::Oware::Rules;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# The bot.
#
# Nothing here tests how WELL it plays. That is xt/bot-ladder.t, which is in xt
# because it takes minutes. This file tests that what comes back is legal, that
# it is the same move twice, and that the seat is part of the draw.
#
# The levels used here are the cheap ones on purpose: level 5 takes about a
# minute for one game and there is nothing in this file that a deeper search
# would exercise.

subtest 'the levels, and what a rung means' => sub {
	is_deeply([ Game::Oware::Bot->levels ], [ 1 .. 5 ], 'five rungs, ascending');

	my $setting = Game::Oware::Bot->setting_for(3);
	ok($setting->{depth} > 0, 'a rung has a depth');
	ok($setting->{nodes} > 0, 'and a node budget');

	eval { Game::Oware::Bot->new(level => 6) };
	like($@, qr/there is no level 6/, 'an unknown level is programmer error');

	eval { Game::Oware::Bot->new(level => 0) };
	like($@, qr/there is no level 0/, 'and so is nought');
};

subtest 'choose answers only when it is asked properly' => sub {
	my $game = Game::Oware->new(seed => 'x' x 32);
	my $bot  = Game::Oware::Bot->new(level => 1, seed => 'b');

	ok(defined $bot->choose($game, 'p1'), 'on turn, it answers');
	is($bot->choose($game, 'p2'), undef, 'off turn, it does not');

	$game->resign('p1');
	is($bot->choose($game, 'p2'), undef, 'and once the game is over, it does not');
};

# THE GUARD THAT MATTERS MOST IN THIS FILE.
#
# plan_game_oware/03 recorded that removing the feeding filter from legal_moves
# leaves 163 of 167 assertions passing: four assertions stand between this
# engine and a legal list that offers illegal moves. The bot is built directly
# on that list, so this asserts membership on every ply of several whole games
# AND counts the plies where the filter was actually pruning, so a position that
# never starves anybody cannot make it pass vacuously.
subtest 'every move it returns is one the game offered' => sub {
	my $pruned = 0;
	my $plies  = 0;

	for my $trial (1 .. 4) {
		my $game = Game::Oware->new(seed => "seed-$trial");
		my %bot = map {
			$_ => Game::Oware::Bot->new(level => 2, seed => "bot-$trial-$_")
		} qw/ p1 p2 /;

		while ($game->status eq 'active' && $plies < 800) {
			my ($seat) = $game->waiting_on;
			my $legal = $game->legal($seat);
			last unless @$legal;

			my @sowable = Game::Oware::Rules->sowable($game->board, $seat);
			$pruned++ if @sowable > @$legal;

			my $house = $bot{$seat}->choose($game, $seat);
			ok(scalar(grep { $_ == $house } @$legal),
				"trial $trial: $house was on the legal list")
				or diag 'legal was: ' . join(',', @$legal);

			my $out = $game->play($seat, $house);
			ok(!(ref $out && $out->isa('Game::Oware::Error')),
				'and the game accepted it')
				or diag $out->stringify;

			$plies++;
		}
	}

	cmp_ok($plies, '>', 100, 'that was a lot of plies');
	cmp_ok($pruned, '>', 0,
		'and the feeding filter pruned the list on some of them, so this was not vacuous');
	diag("$plies plies, of which $pruned had the feeding filter pruning");
};

subtest 'the same seed and seat choose the same move twice' => sub {
	my $one = Game::Oware->new(seed => 'x' x 32);
	my $two = Game::Oware->new(seed => 'x' x 32);

	my $a = Game::Oware::Bot->new(level => 3, seed => 'same');
	my $b = Game::Oware::Bot->new(level => 3, seed => 'same');

	for my $ply (1 .. 12) {
		my ($seat) = $one->waiting_on;
		my $first  = $a->choose($one, $seat);
		my $second = $b->choose($two, $seat);
		is($first, $second, "ply $ply: the same move");
		$one->play($seat, $first);
		$two->play($seat, $second);
	}

	is($one->to_text, $two->to_text, 'and the two games are the same game');
};

# THE GOOFSPIEL GUARD. A bot whose tie-break hashes only its seed is the same
# bot in both seats, so both open identically and a human reads the rule off two
# games. Asserted on the draw itself rather than on play, because two seats own
# different houses and their choices cannot be compared directly.
subtest 'the seat is part of the draw, not just the seed' => sub {
	my $game = Game::Oware->new(seed => 'x' x 32);
	my $bot  = Game::Oware::Bot->new(level => 1, seed => 'one-seed');

	my $as_p1 = $bot->_draw($game, 'p1', 1000);
	my $as_p2 = $bot->_draw($game, 'p2', 1000);

	isnt($as_p1, $as_p2, 'the same seed in two seats draws differently');

	my $other = Game::Oware::Bot->new(level => 1, seed => 'another-seed');
	isnt($bot->_draw($game, 'p1', 1000), $other->_draw($game, 'p1', 1000),
		'and two seeds in one seat draw differently');
};

subtest 'the ply is part of the draw as well' => sub {
	my $game = Game::Oware->new(seed => 'x' x 32);
	my $bot  = Game::Oware::Bot->new(level => 1, seed => 'one-seed');

	my $first = $bot->_draw($game, 'p1', 1000);
	$game->play('p1', 0);
	$game->play('p2', 6);
	my $later = $bot->_draw($game, 'p1', 1000);

	isnt($first, $later, 'or a blundering bot would blunder in lockstep');
};

subtest 'a position with one legal move is played without searching' => sub {
	# p2 is starved and only F reaches, so the feeding filter leaves one move.
	my $game = Game::Oware->new(seed => 'x' x 32,
		board => [ 1, 0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 20, 23 ]);

	is_deeply($game->legal('p1'), [ 5 ], 'one legal move');

	my $bot = Game::Oware::Bot->new(level => 5, seed => 'b');
	is($bot->choose($game, 'p1'), 5, 'and that is what it plays');
	is($bot->last_search->{nodes}, 0, 'without spending a node on it');
};

# A CAPTURE THE BOT SHOULD ACTUALLY WANT, which is not the same as any capture.
#
# The first draft of this vector gave p1 a row of single seeds, so taking three
# left five houses at one for the opponent to harvest, and the bot declined it -
# correctly. The VULNERABLE term exists to make exactly that judgement, so a
# test asserting "always take the capture" would have been asserting the bug.
#
# Here p1 keeps a full row, so the capture costs nothing and every level that
# does not blunder takes one.
subtest 'it takes a capture that costs it nothing' => sub {
	my @board = ( 4, 4, 4, 4, 4, 1, 2, 4, 4, 4, 4, 4, 3, 2 );

	for my $level (3, 4) {
		my $game = Game::Oware->new(seed => 'x' x 32, board => [ @board ]);
		my $bot  = Game::Oware::Bot->new(level => $level, seed => 'b');

		my $house = $bot->choose($game, 'p1');
		my (undef, $move) =
			Game::Oware::Rules->resolve($game->board, $house, 'p1', 'abapa');

		cmp_ok($move->taken, '>', 0, "level $level captures rather than shuffling");
	}
};

# The other half of the same judgement, and the reason the VULNERABLE term is
# worth its weight: here the capture is available and taking it is bad.
subtest 'and declines one that hollows out its own row' => sub {
	my $game = Game::Oware->new(seed => 'x' x 32,
		board => [ 1, 1, 1, 1, 1, 1, 2, 5, 5, 5, 5, 5, 8, 8 ]);

	my (undef, $greedy) =
		Game::Oware::Rules->resolve($game->board, 5, 'p1', 'abapa');
	is($greedy->taken, 3, 'sowing F would take three seeds');

	my $bot = Game::Oware::Bot->new(level => 3, seed => 'b');
	isnt($bot->choose($game, 'p1'), 5,
		'and the bot does not, because it would leave five houses at one');
};

subtest 'last_search reports what it did' => sub {
	my $game = Game::Oware->new(seed => 'x' x 32);
	my $bot  = Game::Oware::Bot->new(level => 3, seed => 'b');

	$bot->choose($game, 'p1');
	my $search = $bot->last_search;

	cmp_ok($search->{nodes}, '>', 0, 'it visited nodes');
	cmp_ok($search->{depth}, '>', 0, 'to some depth');
	ok(defined $search->{score}, 'and came back with a score');
	ok(defined $search->{move}, 'and a move');
};

subtest 'the node budget is respected' => sub {
	my $game = Game::Oware->new(seed => 'x' x 32);

	for my $level (2, 3, 4) {
		my $bot = Game::Oware::Bot->new(level => $level, seed => 'b');
		$bot->choose($game, 'p1');
		my $budget = Game::Oware::Bot->setting_for($level)->{nodes};

		cmp_ok($bot->last_search->{nodes}, '<=', $budget * 2,
			"level $level stays near its budget of $budget");
	}
};

done_testing;
