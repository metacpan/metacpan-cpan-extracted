#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Board;
use Game::Oware::Variant ();

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# D2, THE CYCLE RULE, WHICH IS A HOUSE RULE AND NOT THE RULE OF OWARE.
#
# The published ending is kept and the trigger is replaced, because "if both
# players agree" has no mechanism where one seat is a program. Two triggers:
# the same position for the third time, or a ply count with no seed entering a
# store. Either fires and each seat sweeps its own row.
#
# TRIGGER A IS EXERCISED BY A REAL CIRCUIT, not by a hand-set counter. Trigger B
# is not: a genuine five-hundred-ply capture-free stretch is not something to
# construct by hand, so that subtest sets the counter and says so. Which half is
# real and which is white box is written next to each.

subtest 'the position key is the board AND the side to move' => sub {
	my $g = Game::Oware->new(seed => 'x' x 32);

	my @keys = keys %{ $g->seen };
	is(scalar @keys, 1, 'the opening position is counted at once');
	like($keys[0], qr/:p1\z/, 'and the key carries whose move it is');

	# Two games with identical boards but different seats to move must not
	# share a key, or a repetition would be counted that never happened.
	my $p2 = Game::Oware->new(seed => 'x' x 32);
	$p2->turn('p2');
	$p2->seen({});
	$p2->_remember;

	isnt((keys %{ $p2->seen })[0], $keys[0], 'the same board with the other seat differs');
};

# THE CIRCUIT. p1 has one seed in F and p2 one in f, everything else banked.
# Each seat has exactly one legal move and playing it hands the single seed
# forward, so the position walks round the ring and returns to itself after
# twelve plies. Nothing is ever captured, because every house goes from nought
# to one.
#
# Derived by hand and then confirmed against the engine, because a search over
# seven hundred low-seed games under a first-legal-move policy found no
# repetition whatever.
#
# THAT SEARCH WAS MISLEADING AND xt/cycle-measure.t CORRECTS IT: over three
# hundred games played by actual bots, threefold repetition ended 24 of them.
# Repetition is not rare, it is rare under a policy that does not play like a
# player. The circuit below is still the only repetition small enough to write
# down and assert every ply of.
subtest 'a real repetition fires the cycle, after two full laps' => sub {
	my $g = Game::Oware->new(seed => 'x' x 32,
		board => [ (0) x 5, 1, (0) x 5, 1, 23, 23 ]);

	my @positions;
	my $plies = 0;

	while ($g->status eq 'active' && $plies < 40) {
		my ($seat) = $g->waiting_on;
		my $legal = $g->legal($seat);
		is(scalar @$legal, 1, "ply $plies: exactly one move is legal")
			if $plies < 3;
		last unless @$legal;

		push @positions, join('', @{ $g->board }[0 .. 11]) . ':' . $g->turn;

		my $out = $g->play($seat, $legal->[0]);
		last if ref $out && $out->isa('Game::Oware::Error');
		$plies++;
	}

	is($positions[12], $positions[0], 'the circuit has a period of twelve plies');
	is($plies, 24, 'so the third occurrence arrives on ply twenty-four');

	is($g->status, 'finished', 'and the game ends there');
	is($g->result->reason, 'cycle', 'by the cycle rule');
	is($g->no_capture, 24, 'with nothing captured the whole way');

	my ($cycle) = grep { $_->{kind} eq 'cycle' } @{ $g->events };
	ok($cycle, 'the log says so');
	is($cycle->{payload}{why}, 'repetition', 'and which trigger fired');
	is($cycle->{payload}{times}, 3, 'and how many times the position occurred');

	is(Game::Oware::Board->seeds_on_side($g->board, 'p1'), 0, 'the board is swept');
	is(Game::Oware::Board->seeds_on_side($g->board, 'p2'), 0, 'on both sides');
	is_deeply($g->captured, { p1 => 24, p2 => 24 },
		'each seat took its own row, which is the split and not the one-sided sweep');
	is($g->result->result, 'draw', 'and twenty-four each is a draw');
	is(Game::Oware::Board->total($g->board), 48, 'forty-eight seeds');
};

# WHITE BOX, AND SAYING SO. The counter is set rather than earned: the shipped
# cap is five hundred plies and xt/cycle-measure.t is where it was measured.
# What is asserted here is the trigger and the sweep, not the journey.
subtest 'the ply counter fires the same ending' => sub {
	my $limit = Game::Oware::Variant::plies_without_capture('abapa');
	my $g = Game::Oware->new(seed => 'x' x 32);

	$g->no_capture($limit - 1);

	my $move = $g->play('p1', 0);
	is($move->taken, 0, 'a quiet move, so the counter goes up rather than back to nought');

	is($g->status, 'finished', 'and it reaches the cut');
	is($g->result->reason, 'cycle', 'ending the game by the cycle rule');

	my ($cycle) = grep { $_->{kind} eq 'cycle' } @{ $g->events };
	is($cycle->{payload}{why}, 'plies', 'the other trigger');
	is($cycle->{payload}{plies}, $limit, 'at the cut');

	is_deeply($g->captured, { p1 => 24, p2 => 24 },
		'each seat took its own row');
	is(Game::Oware::Board->total($g->board), 48, 'forty-eight seeds');
};

# THE ARGUMENT FOR CLEARING THE TABLE. Seeds go into a store and never come out,
# so a capture changes the stores monotonically and a position can only ever
# repeat inside one capture-free stretch. That is what makes the table free to
# keep: it is emptied every time a capture makes its contents unreachable.
subtest 'a capture resets both counters' => sub {
	my $g = Game::Oware->new(seed => 'x' x 32,
		board => [ 0, 0, 0, 0, 0, 1, 1, 4, 4, 4, 4, 4, 10, 10 ]);

	$g->no_capture(17);
	ok(scalar keys %{ $g->seen }, 'the table has something in it');

	my $move = $g->play('p1', 5);

	is($move->taken, 2, 'a capture');
	is($g->no_capture, 0, 'so the ply counter goes back to nought');
	is(scalar keys %{ $g->seen }, 1,
		'and the table holds only the position that follows it');
};

subtest 'a quiet move does not reset either' => sub {
	my $g = Game::Oware->new(seed => 'x' x 32);

	$g->play('p1', 0);
	is($g->no_capture, 1, 'one quiet ply');
	$g->play('p2', 6);
	is($g->no_capture, 2, 'two');
	is(scalar keys %{ $g->seen }, 3, 'and every position is still remembered');
};

subtest 'the trigger numbers come from the variant, not from the code' => sub {
	is(Game::Oware::Variant::repetition_limit('abapa'), 3, 'three occurrences');
	is(Game::Oware::Variant::plies_without_capture('abapa'), 500,
		'and five hundred plies, measured in xt/cycle-measure.t rather than chosen');
};

done_testing;
