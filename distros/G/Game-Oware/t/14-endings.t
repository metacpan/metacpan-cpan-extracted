#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Board;
use Game::Oware::Scoring;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# The four natural endings, the three service ones, and the two sweeps.
#
# Oware has FOUR ways to finish naturally and only TWO result tokens for them,
# because the site this engine feeds constrains a column to five values. Which
# of the four happened is the reason, and every subtest here asserts both.

sub game {
	my ($houses, $p1, $p2) = @_;
	return Game::Oware->new(
		seed  => 'x' x 32,
		board => [ @$houses, $p1, $p2 ],
	);
}

subtest 'the target: twenty-five or more' => sub {
	# p1 holds 23. F has one seed, a has two: sowing F brings a to three and
	# captures it, carrying p1 to twenty-six. Twenty-five OR MORE is the rule,
	# and this is why: one capture can step straight over it.
	my $g = game([ 0, 0, 0, 0, 0, 1, 2, 4, 0, 0, 0, 0 ], 23, 18);

	my $move = $g->play('p1', 5);

	is($move->taken, 3, 'three seeds captured');
	is($g->status, 'finished', 'and the game is over');
	is($g->winner, 'p1', 'p1 won');
	is($g->result->result, 'score', 'by score');
	is($g->result->reason, 'target', 'because it reached the target');
	is($g->captured->{p1}, 26, 'with twenty-six, not twenty-five');
	is(Game::Oware::Board->total($g->board), 48, 'forty-eight seeds');

	is_deeply($g->result->places, { p1 => 1, p2 => 2 }, 'and the places');
	is_deeply($g->score, { p1 => 26, p2 => 18 }, 'a natural ending has a score');
	ok($g->result->natural, 'and says so');
};

# TWENTY-FOUR EACH CANNOT BE REACHED BY A CAPTURE UNDER ABAPA, AND THE PROOF IS
# ARITHMETIC RATHER THAN A SEARCH.
#
# The three totals always sum to forty-eight, so for both stores to hold
# twenty-four the board has to be EMPTY. A capture that empties the board has
# taken every seed the opponent had, which is a grand slam, which under abapa is
# forfeited. So the capture that would level the score is exactly the capture
# the grand slam rule protects, every time.
#
# The branch is therefore not dead, it is variant-specific: under awari the slam
# is legal when it is the only move, so the capture is made and the ending is
# reachable. Both halves are asserted, and a reader who finds `even` never
# firing in an abapa game now knows why.
subtest 'twenty-four each is a draw, and only awari can get there' => sub {
	my @board = ( 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0 );

	my $abapa = game([ @board ], 22, 24);
	my $one   = $abapa->play('p1', 5);

	ok($one->slammed, 'under abapa the levelling capture is a grand slam');
	is($one->taken, 0, 'so it takes nothing');
	is($abapa->result->reason, 'no_feed',
		'and the game ends some other way entirely');
	is($abapa->captured->{p1}, 22, 'p1 never reached twenty-four');

	my $ends = Game::Oware->new(seed => 'x' x 32, variant => 'awari',
		board => [ @board, 22, 24 ]);

	is_deeply($ends->legal('p1'), [ 5 ],
		'under awari the slam is legal here, because it is the only move');

	my $two = $ends->play('p1', 5);

	ok($two->slammed, 'it is still a grand slam');
	is($two->taken, 2, 'but the capture is made');
	is($ends->result->result, 'draw', 'and the game is a draw');
	is($ends->result->reason, 'even', 'because both stores reached twenty-four');
	is($ends->winner, undef, 'a draw has no winner');
	is_deeply($ends->result->places, { p1 => 1, p2 => 1 }, 'and both place first');
	is(Game::Oware::Board->total($ends->board), 48, 'forty-eight seeds');
};

subtest 'the failed feed, reached directly' => sub {
	# p1 to move, p2 starved, and none of p1 houses reach: A needs six, B five.
	my $g = Game::Oware->new(seed => 'x' x 32,
		board => [ 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 23 ]);

	is_deeply($g->legal('p1'), [], 'p1 has no legal move at all');
	is($g->status, 'active', 'but the game has not noticed, because nobody has moved');

	# The ending is reached by a move, so drive it from one ply earlier: p2
	# plays its last seed into p1, then p1 cannot feed back.
	my $h = Game::Oware->new(seed => 'x' x 32,
		board => [ 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 19, 23 ]);
	$h->turn('p2');

	$h->play('p2', 11);

	is($h->status, 'finished', 'the game ends');
	is($h->result->reason, 'no_feed', 'because p1 could not feed');
	is($h->captured->{p1}, 19 + 6, 'and p1 swept every seed on the board');
	is(Game::Oware::Board->seeds_on_side($h->board, 'p1'), 0, 'the board is empty');
	is(Game::Oware::Board->total($h->board), 48, 'forty-eight seeds');
};

# THE SUBTEST THE TWO SWEEPS EXIST FOR. One board, two sweeps, two different
# results. A single sweep() taking an optional seat would pass every other test
# in this file and fail only here.
subtest 'the two sweeps are not the same gesture' => sub {
	my $board = [ 1, 1, 1, 1, 1, 1, 5, 5, 5, 5, 5, 5, 6, 6 ];

	my $to_p1  = Game::Oware::Scoring->sweep_to($board, 'p1');
	my $split  = Game::Oware::Scoring->sweep_split($board);

	is_deeply(Game::Oware::Scoring->captured($to_p1), { p1 => 42, p2 => 6 },
		'the failed feed gives every seed to one seat');
	is_deeply(Game::Oware::Scoring->captured($split), { p1 => 12, p2 => 36 },
		'the cycle gives each seat its own row');

	isnt($to_p1->[12], $split->[12], 'and the two disagree, which is the whole point');

	is(Game::Oware::Board->total($to_p1), 48, 'forty-eight either way');
	is(Game::Oware::Board->total($split), 48, 'and the other way too');

	is_deeply($board, [ 1, 1, 1, 1, 1, 1, 5, 5, 5, 5, 5, 5, 6, 6 ],
		'neither modified the board it was given');
};

# AND YET THE TWO SWEEPS CANNOT BE TOLD APART WHERE THE ENGINE USES THEM.
#
# Swapping sweep_to for sweep_split in the failed-feed ending passes this whole
# suite - 409 assertions, none of them caught it - and that is not a missing
# test. The failed feed fires only when the opponent is starved, so their row is
# empty, so "everything to one seat" and "each row to its own store" are the
# same operation at every position where either is reachable.
#
# So what is asserted is the PROPERTY that makes them equal, rather than a
# distinction the engine cannot exhibit. If a future change lets the failed feed
# fire while the other seat still holds seeds, this fails and the choice of
# sweep starts to matter.
subtest 'at a failed feed the other row is empty, which is why the sweep cannot be got wrong' => sub {
	my $g = Game::Oware->new(seed => 'x' x 32,
		board => [ 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 19, 23 ]);
	$g->turn('p2');

	$g->play('p2', 11);

	is($g->result->reason, 'no_feed', 'the ending fired');

	my ($sweep) = grep { $_->{kind} eq 'sweep' } @{ $g->events };
	ok($sweep, 'and the log records it');
	is($sweep->{payload}{p}, 'p1', 'naming the seat that could not move');

	# Rebuild the position as it stood when the sweep ran: p2 had just emptied
	# its last house into p1's row.
	my $at_sweep = [ 4, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 23 ];

	is(Game::Oware::Board->seeds_on_side($at_sweep, 'p2'), 0,
		'the seat NOT sweeping held nothing, because that is what starved means');

	is_deeply(Game::Oware::Scoring->sweep_to($at_sweep, 'p1'),
		Game::Oware::Scoring->sweep_split($at_sweep),
		'so the two sweeps agree here, and the engine cannot pick the wrong one');
};

subtest 'the three service endings, none of which has a score' => sub {
	for my $case (
		[ 'timeout', sub { $_[0]->timeout('p1') }, 'p2', 'timeout', 'timeout' ],
		[ 'resign',  sub { $_[0]->resign('p1') },  'p2', 'resign',  'resign'  ],
	) {
		my ($name, $do, $winner, $result, $reason) = @$case;
		my $g = Game::Oware->new(seed => 'x' x 32);

		my $out = $do->($g);

		is($g->status, 'finished', "$name finishes the game");
		is($g->winner, $winner, "$name gives it to the other seat");
		is($out->result, $result, "$name result token");
		is($out->reason, $reason, "$name reason");
		ok(!$out->natural, "$name is not a natural ending");
		is($out->score, undef, "$name has no official score");
		ok($out->captured->{p1} == 0, "$name still reports what was captured");
	}

	my $g = Game::Oware->new(seed => 'x' x 32);
	my $out = $g->abandon;
	is($out->result, 'abandoned', 'abandon result token');
	is($g->winner, undef, 'and nobody won it');
	is_deeply($out->places, { p1 => 1, p2 => 1 },
		'so both seats place first, which is what makes it unrated downstream');
};

subtest 'the seed is held, published at the end, and never read' => sub {
	my $g = Game::Oware->new(seed => 'abc');

	is($g->seed, undef, 'no seed while the game is active');
	$g->resign('p1');
	is($g->seed, 'abc', 'and it is there once it is over');

	my $none = Game::Oware->new;
	$none->resign('p1');
	is($none->seed, undef, 'a game built without one still works');
};

subtest 'places and scores are the shapes a consumer wants' => sub {
	my $g = Game::Oware->new(seed => 'x' x 32);

	is($g->places, undef, 'places is undef while running, not a live standing');
	is_deeply($g->scores, { p1 => { current => 0 }, p2 => { current => 0 } },
		'scores is a hash per seat, never a bare number');
	is($g->score, undef, 'and score refuses to answer');
};

done_testing;
