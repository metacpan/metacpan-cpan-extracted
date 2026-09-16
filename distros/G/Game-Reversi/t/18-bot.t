#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Bot;

# The bot's contract: it always returns something legal when it is its turn, it
# returns nothing when it is not, and it never breaks a game.
#
# How WELL it plays is not asserted here. That is xt/bot-ladder.t, which is slow
# and lives outside the installed suite; and t/19-bot-corners.t, which asserts
# the one strategic property that is derivable rather than a matter of taste.

my $B = 'Game::Reversi::Board';

sub sq { return $B->square_of(split //, $_[0]) }

subtest 'levels, and a level that does not exist' => sub {
	is_deeply([ Game::Reversi::Bot->levels ], [ 1 .. 5 ], 'five levels');
	is(Game::Reversi::Bot->new->level, 3, 'three by default');
	is(Game::Reversi::Bot->new(level => 1)->level, 1, 'or whatever was asked for');

	ok(!eval { Game::Reversi::Bot->new(level => 9); 1 }, 'level 9 is refused');
	ok(!eval { Game::Reversi::Bot->new(level => 0); 1 }, 'and level 0');
	done_testing();
};

subtest 'choose returns undef when there is nothing for it to do' => sub {
	my $game = Game::Reversi->new(variant => 'historic');
	my $bot = Game::Reversi::Bot->new(level => 2, seed => 'x');

	is($bot->choose($game, $B->other($game->turn)), undef,
		'undef for the seat that is not on turn');
	is($bot->choose($game, undef), undef, 'undef for no seat at all');

	$game->resign('b');
	is($game->status, 'finished', 'once the game is over');
	is($bot->choose($game, 'b'), undef, 'undef for the seat that resigned');
	is($bot->choose($game, 'w'), undef, 'and for the other one');
	done_testing();
};

subtest 'every level plays without breaking the game' => sub {
	# Levels 1 to 3 play the game out. Levels 4 and 5 play the opening and a few
	# moves and then stop, because a full game at level 5 takes most of a minute
	# and this file is part of the installed suite, run on every `make test` and
	# by every smoker. xt/bot-ladder.t plays them out in full, where the time is
	# affordable because nobody installing the module pays it.
	my %cap = (1 => 200, 2 => 200, 3 => 200, 4 => 9, 5 => 8);

	for my $level (Game::Reversi::Bot->levels) {
		my $game = Game::Reversi->new(variant => 'historic');
		my %bot = map { $_ => Game::Reversi::Bot->new(level => $level, seed => "L$level$_") }
		          qw(b w);
		my ($moves, $illegal) = (0, 0);

		while ($game->status eq 'active' && $moves < $cap{$level}) {
			my $colour = $game->turn;
			my $move = $bot{$colour}->choose($game, $colour);
			last unless $move;

			# Whatever it chose has to be one of the moves it was offered.
			my %offered = map { $_->square => 1 } @{ $game->legal($colour) };
			$illegal++ unless $offered{ $move->square };

			my $played = $game->play($colour, $move->square);
			$illegal++ if ref $played && $played->isa('Game::Reversi::Error');
			$moves++;
		}

		is($illegal, 0, "level $level never chose a move it was not offered");

		if ($cap{$level} > 100) {
			cmp_ok($moves, '>', 10, "level $level: it kept going");
			is($game->status, 'finished', "level $level played the game out");
			my $score = $game->score;
			is($score->{b} + $score->{w}, 64, "level $level: the score totals 64");
		}
		else {
			is($moves, $cap{$level},
				"level $level: played all $cap{$level} moves it was allowed");
			is($game->status, 'active', "level $level: stopped early, on purpose");
		}
	}
	done_testing();
};

subtest 'the budget is a ceiling, and it is respected' => sub {
	# Budget in nodes, never in seconds: a loaded machine has to choose the same
	# move as an idle one. An earlier version allowed four times the budget
	# before stopping, which made a level slower than it claimed to be by
	# exactly that factor.
	my %ceiling = (1 => 60, 2 => 400, 3 => 1500, 4 => 5000, 5 => 8000);

	for my $level (Game::Reversi::Bot->levels) {
		my $game = Game::Reversi->new(variant => 'othello');
		my $bot = Game::Reversi::Bot->new(level => $level, seed => 'budget');
		my $worst = 0;
		my $moves = 0;

		while ($game->status eq 'active' && $moves++ < 5) {
			my $move = $bot->choose($game, $game->turn) or last;
			my $nodes = $bot->last_search->{nodes} // 0;
			$worst = $nodes if $nodes > $worst;
			$game->play($game->turn, $move->square);
		}

		cmp_ok($worst, '<=', $ceiling{$level} + 1,
			"level $level stayed inside its budget of $ceiling{$level} nodes");
		cmp_ok($worst, '>', 0, "level $level actually searched something") if $level > 1;
	}
	done_testing();
};

subtest 'last_search says what it did' => sub {
	my $game = Game::Reversi->new(variant => 'othello');
	my $bot = Game::Reversi::Bot->new(level => 3, seed => 'report');
	$bot->choose($game, 'b');

	my $search = $bot->last_search;
	ok($search, 'there is a report');
	cmp_ok($search->{nodes}, '>', 0, 'it searched some nodes');
	cmp_ok($search->{depth}, '>', 0, 'to some depth');
	ok(!$search->{opening}, 'and it was a search, not an opening draw');

	# The historic opening is drawn rather than searched below level 5.
	my $historic = Game::Reversi->new(variant => 'historic');
	my $opener = Game::Reversi::Bot->new(level => 3, seed => 'report');
	$opener->choose($historic, 'b');
	ok($opener->last_search->{opening}, 'a placement is drawn, not searched');
	is($opener->last_search->{nodes}, 0, 'so it costs no nodes');
	done_testing();
};

subtest 'the two seats do not open the same way' => sub {
	# The Goofspiel lesson, which cost that game every bot match it ever played:
	# a bot whose seed omits the seat is the same bot on both sides. Here it
	# would mean both seats reaching for the same centre square and the six
	# openings collapsing to one.
	#
	# Asserted over seeds rather than once, because any single pair could agree
	# by chance out of four choices.
	my ($same, $total) = (0, 0);
	for my $seed (1 .. 8) {
		my $game = Game::Reversi->new(variant => 'historic');
		my $black = Game::Reversi::Bot->new(level => 3, seed => $seed);
		my $white = Game::Reversi::Bot->new(level => 3, seed => $seed);

		my $first = $black->choose($game, 'b');
		# What would White have picked from the same position?
		my $would = $white->choose(
			Game::Reversi->from_board($game->board, turn => 'w'), 'w');
		$total++;
		$same++ if $would && $first->square == $would->square;
	}

	cmp_ok($same, '<', $total,
		"the seats disagreed at least once in $total seeds, so the seat is in the seed");
	done_testing();
};

subtest 'the six openings all get played' => sub {
	# The point of drawing the opening from a seed rather than searching it: if
	# the bot always opened the same way, five of the six historic positions
	# would never be seen by anybody.
	my %reached;
	for my $seed (1 .. 20) {
		my $game = Game::Reversi->new(variant => 'historic');
		my %bot = map { $_ => Game::Reversi::Bot->new(level => 2, seed => "$seed$_") }
		          qw(b w);
		for (1 .. 4) {
			my $move = $bot{ $game->turn }->choose($game, $game->turn) or last;
			$game->play($game->turn, $move->square);
		}
		my @black = sort map { $B->name_of($_) }
		            grep { ($game->board->[$_] // '') eq 'b' } 0 .. 63;
		$reached{ join ',', @black }++;
	}

	cmp_ok(scalar keys %reached, '>', 1,
		'more than one of the six openings is reached across 20 seeds');
	done_testing();
};

subtest 'a bot game replays, which means the bot is deterministic' => sub {
	# Budget in nodes rather than seconds is what buys this: the same bot in the
	# same position chooses the same move however loaded the machine is, so a
	# bot game is reproducible from its log.
	my $game = Game::Reversi->new(variant => 'historic');
	my %bot = map { $_ => Game::Reversi::Bot->new(level => 2, seed => "r$_") } qw(b w);
	while ($game->status eq 'active') {
		my $move = $bot{ $game->turn }->choose($game, $game->turn) or last;
		$game->play($game->turn, $move->square);
	}

	my $again = Game::Reversi->new(variant => 'historic');
	my %bot2 = map { $_ => Game::Reversi::Bot->new(level => 2, seed => "r$_") } qw(b w);
	while ($again->status eq 'active') {
		my $move = $bot2{ $again->turn }->choose($again, $again->turn) or last;
		$again->play($again->turn, $move->square);
	}

	is($again->to_text, $game->to_text, 'the same bots play the same game twice');

	my $replayed = Game::Reversi->new(variant => 'historic');
	ok(eval { $replayed->replay($game->events); 1 }, 'and the log replays') or diag $@;
	is_deeply($replayed->board, $game->board, 'to the same board');
	done_testing();
};

done_testing();
