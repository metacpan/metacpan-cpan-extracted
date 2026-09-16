#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;
use Game::Reversi::Scoring;
use Game::Reversi::Result;

# The scoring rule, the tie the formula cannot produce, and what a game that was
# stopped rather than finished is worth.
#
# Parentheses on every Test::More call whose first argument is a Class->method
# call: without them it parses as indirect object syntax.

my $B = 'Game::Reversi::Board';
my $S = 'Game::Reversi::Scoring';

sub sq { return $B->square_of(split //, $_[0]) }

# A board holding exactly these many discs of each colour, and nothing else
# about it is meaningful. Scoring is a pure function of the counts and the empty
# squares, so a fixture for it does not have to be a position any game could
# reach, and pretending otherwise would make these tests harder to read for no
# gain.
sub board_with {
	my ($black, $white) = @_;
	my $board = $B->empty;
	my $at = 0;
	$board->[ $at++ ] = 'b' for 1 .. $black;
	$board->[ $at++ ] = 'w' for 1 .. $white;
	return $board;
}

subtest 'count is what is on the board' => sub {
	my $board = board_with(20, 14);
	is_deeply($S->count($board), { b => 20, w => 14 }, 'twenty and fourteen');
	is($B->empties($board), 30, 'with thirty squares empty');
	done_testing();
};

subtest 'score gives the empty squares to the winner' => sub {
	# WOF, World Othello Championships rules, IV.7: "The official score of the
	# game will be determined by counting up the discs of each colour on the
	# board, counting empty squares for the winner."
	#
	# So the game above is recorded 50-14 and not 20-14. The other rule in
	# circulation, which is simply the absence of that sentence, would record
	# 20-14; both agree that Black won.
	my $board = board_with(20, 14);

	is_deeply($S->score($board), { b => 50, w => 14 },
		'20 discs plus 30 empty squares is a score of 50');
	is_deeply($S->count($board), { b => 20, w => 14 },
		'while count still says what is actually on the board');

	isnt($S->score($board)->{b}, $S->count($board)->{b},
		'the two really are different numbers, which is why they are two names');
	done_testing();
};

subtest 'a score always totals 64, whatever the board looks like' => sub {
	# The cheapest real assertion in the distribution: one identity that catches
	# a mis-awarded empty square, a double count and a lost disc at once.
	for my $case ([ 20, 14 ], [ 1, 58 ], [ 63, 0 ], [ 0, 0 ], [ 32, 32 ], [ 33, 31 ], [ 2, 3 ]) {
		my ($black, $white) = @$case;
		my $score = $S->score(board_with($black, $white));
		is($score->{b} + $score->{w}, 64, "$black and $white on the board scores 64 in total");
	}
	done_testing();
};

subtest 'on a full board the two numbers agree' => sub {
	my $board = board_with(33, 31);
	is($B->empties($board), 0, 'nothing empty');
	is_deeply($S->score($board), $S->count($board),
		'so there is nothing to award and score is the count');
	done_testing();
};

subtest 'an equal game is recorded 32-32, however many squares are empty' => sub {
	# THE BRANCH THE FORMULA CANNOT PRODUCE. "Counting empty squares for the
	# winner" has no answer when there is no winner, and WOF resolves it by
	# fiat in the same sentence: "In the event of a draw, the score will always
	# be 32-32."
	#
	# So a game ending 25-25 with fourteen squares empty is officially 32-32,
	# and not 25-25, and not 32-32 only because the board happened to be full.
	# Nothing derives this; it has to be written.
	my $board = board_with(25, 25);
	is($B->empties($board), 14, 'fourteen squares empty');
	is_deeply($S->count($board), { b => 25, w => 25 }, 'and the discs are level');

	is_deeply($S->score($board), { b => 32, w => 32 },
		'the score is 32-32 by fiat, not 25-25');
	is($S->winner($board), undef, 'with no winner');

	# The same rule on a full board, where it looks like arithmetic but is not.
	my $full = board_with(32, 32);
	is($B->empties($full), 0, 'a full level board');
	is_deeply($S->score($full), { b => 32, w => 32 }, 'is also 32-32');
	done_testing();
};

subtest 'the empty squares rule never changes who won' => sub {
	# Stated because it is the reason the choice between the two scoring rules
	# was safe to make: they disagree about the margin and never about the
	# result. The empty squares go to the winner, so they cannot promote anybody.
	for my $case ([ 20, 14 ], [ 1, 58 ], [ 5, 4 ], [ 0, 1 ], [ 30, 30 ]) {
		my ($black, $white) = @$case;
		my $board = board_with($black, $white);
		my $count = $S->count($board);
		my $score = $S->score($board);

		my $by_count = $count->{b} == $count->{w} ? undef
		             : $count->{b} > $count->{w} ? 'b' : 'w';
		my $by_score = $score->{b} == $score->{w} ? undef
		             : $score->{b} > $score->{w} ? 'b' : 'w';
		is($by_score, $by_count, "$black to $white: both rules name the same winner");
		is($S->winner($board), $by_count, 'and so does winner');
	}
	done_testing();
};

# ---- the result object ---------------------------------------------------------

sub played_out {
	my $game = Game::Reversi->new(variant => 'historic');
	while ($game->status eq 'active') {
		my $legal = $game->legal($game->turn);
		last unless @$legal;
		$game->play($game->turn, $legal->[0]->square);
	}
	return $game;
}

subtest 'a finished game carries its result' => sub {
	my $game = played_out();
	my $result = $game->result;

	isa_ok($result, 'Game::Reversi::Result');
	ok($result->natural, 'it reached its own end');
	like($result->result, qr/\A(?:score|draw)\z/, 'so the result is score or draw');
	is($result->winner, $game->winner, 'and it agrees with the game about the winner');

	is_deeply($result->counts, $game->counts, 'it carries the disc counts');
	is($result->score->{b} + $result->score->{w}, 64, 'and a score totalling 64');
	is_deeply($game->score, $result->score, 'which the game hands out too');

	# An unfinished game has neither.
	my $running = Game::Reversi->new(variant => 'historic');
	is($running->result, undef, 'a game in progress has no result');
	is($running->score, undef, 'and no score');
	is($running->places, undef, 'and no standings, because a Reversi midgame lead means little');
	done_testing();
};

subtest 'places are the finishing order, and a tie shares first' => sub {
	my $game = played_out();
	my $places = $game->places;
	my $winner = $game->winner;

	if (defined $winner) {
		is($places->{$winner}, 1, 'the winner comes first');
		is($places->{ $B->other($winner) }, 2, 'and the loser second');
	}
	else {
		is_deeply($places, { b => 1, w => 1 }, 'a tie puts both first');
	}

	# The tie case built directly, since a played out game may not produce one.
	my $tie = Game::Reversi::Result->new(
		winner => undef, result => 'draw',
		counts => { b => 32, w => 32 }, score => { b => 32, w => 32 },
		places => { b => 1, w => 1 });
	is_deeply($tie->places, { b => 1, w => 1 }, 'both seats first on a tie');
	is($tie->winner, undef, 'with nobody named');
	done_testing();
};

# ---- games that were stopped rather than finished ------------------------------

subtest 'a timeout ends the game without the engine pricing it' => sub {
	# THE ONE PLACE THIS DISTRIBUTION DECLINES TO IMPLEMENT A RULE. The sources
	# give three different answers for a game stopped by a clock: WOF's
	# championship rules guarantee the non-defaulter at least 33-31, the same
	# document scores an abandoned game 64-0, and Wikipedia describes a common
	# procedure guaranteeing only a one disc margin while conceding that "There
	# are varying methods to determine the official score when a player
	# defaults."
	#
	# A timeout is the host talking. So the result names the winner, counts says
	# what was on the board, and score is undef.
	my $game = Game::Reversi->new(variant => 'historic');
	$game->play($game->turn, $game->legal($game->turn)->[0]->square) for 1 .. 6;

	my $result = $game->timeout('b');
	is($game->status, 'finished', 'the game is over');
	is($result->result, 'timeout', 'by timeout');
	is($result->winner, 'w', 'and the seat that did not run out wins');
	ok(!$result->natural, 'it did not reach its own end');
	is($result->score, undef, 'so there is no official score');
	is($game->score, undef, 'and the game does not offer one');
	ok($result->counts, 'but the discs on the board are still counted');
	is_deeply($result->places, { w => 1, b => 2 }, 'and the standings still stand');

	my $last = $game->events->[-1];
	is($last->{kind}, 'game_end', 'the log ends with the end');
	is($last->{payload}{result}, 'timeout', 'naming the reason');
	done_testing();
};

subtest 'an abandoned game has no winner at all' => sub {
	my $game = Game::Reversi->new(variant => 'historic');
	$game->play($game->turn, $game->legal($game->turn)->[0]->square) for 1 .. 5;

	my $result = $game->abandon;
	is($game->status, 'finished', 'over');
	is($result->result, 'abandoned', 'abandoned');
	is($result->winner, undef, 'with nobody winning');
	is($result->score, undef, 'and no official score');
	is_deeply($result->places, { b => 1, w => 1 },
		'nobody finished ahead of anybody');
	done_testing();
};

subtest 'a resignation is the player talking, so it is theirs in the log' => sub {
	my $game = Game::Reversi->new(variant => 'historic');
	$game->play($game->turn, $game->legal($game->turn)->[0]->square) for 1 .. 5;

	my $result = $game->resign('b');
	is($result->result, 'resign', 'resigned');
	is($result->winner, 'w', 'so the other seat wins');
	is($result->score, undef, 'with no official score');

	my ($event) = grep { $_->{kind} eq 'resign' } @{ $game->events };
	is($event->{actor}, 'b',
		'and the event belongs to the player, unlike a timeout which is the host');
	done_testing();
};

subtest 'a stopped game cannot be stopped twice, or played on' => sub {
	my $game = Game::Reversi->new(variant => 'historic');
	$game->resign('b');
	is($game->timeout('w')->code, 'game_over', 'no timeout after the end');
	is($game->abandon->code, 'game_over', 'no abandoning it either');
	is($game->resign('w')->code, 'game_over', 'nor resigning again');
	is($game->play('w', sq('d4'))->code, 'game_over', 'and no moves');
	done_testing();
};

subtest 'a result value the class does not know is programmer error' => sub {
	ok(!eval { Game::Reversi::Result->new(winner => 'b', result => 'vibes',
		counts => {}, score => undef, places => {}); 1 },
		'an unknown result is refused');
	like($@, qr/is not a result/, 'saying so');

	ok(!eval { Game::Reversi::Result->new(winner => 'b', result => 'draw',
		counts => {}, score => undef, places => {}); 1 },
		'and a draw with a winner is refused, because it is a contradiction');
	done_testing();
};

subtest 'a stopped game still replays, because the host has to be told' => sub {
	# timeout and abandon cannot be regenerated from the position: nothing on
	# the board says a clock ran out. So replay applies them from the log rather
	# than skipping them, and this is what proves that path works.
	for my $stop (
		[ timeout   => sub { $_[0]->timeout('b') } ],
		[ abandoned => sub { $_[0]->abandon } ],
		[ resign    => sub { $_[0]->resign('b') } ],
	) {
		my ($name, $do) = @$stop;
		my $game = Game::Reversi->new(variant => 'historic');
		$game->play($game->turn, $game->legal($game->turn)->[0]->square) for 1 .. 6;
		$do->($game);

		my $replayed = Game::Reversi->new(variant => 'historic');
		ok(eval { $replayed->replay($game->events); 1 }, "$name replays") or diag $@;
		is($replayed->status, 'finished', "$name: to a finished game");
		is($replayed->winner, $game->winner, "$name: with the same winner");
		is($replayed->result->result, $name, "$name: and the same reason");
		is_deeply($replayed->events, $game->events, "$name: and the same log");
	}
	done_testing();
};

done_testing();
