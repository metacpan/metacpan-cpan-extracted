#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;

# NOTE: parentheses on every Test::More call whose first argument is a
# Class->method(...) call. See the note at the top of t/01-board.t.

# The log is the serialisation, and replay is what makes it trustworthy.
#
# Only the player events are applied. Every sys event is REGENERATED from the
# position and the resulting log must then match what was handed in, so a log
# that records something this engine would not have produced is refused rather
# than believed. Each of the forgeries below awards seeds to somebody, which is
# what makes them worth refusing.

sub played {
	my ($plies) = @_;
	my $g = Game::Oware->new(seed => 'x' x 32);
	my $n = 0;
	while ($g->status eq 'active' && (!defined $plies || $n < $plies)) {
		my ($seat) = $g->waiting_on;
		my $legal = $g->legal($seat);
		last unless @$legal;
		$g->play($seat, $legal->[0]);
		$n++;
	}
	return $g;
}

subtest 'a whole game replays to the same game' => sub {
	my $original = played();

	ok($original->status eq 'finished', 'the game finished');
	cmp_ok(scalar @{ $original->events }, '>', 20, 'and it was a real game');

	my $replayed = Game::Oware->new(seed => 'x' x 32)->replay($original->events);

	is_deeply($replayed->board, $original->board, 'the same board');
	is($replayed->status, $original->status, 'the same status');
	is($replayed->turn, $original->turn, 'the same seat on turn');
	is($replayed->no_capture, $original->no_capture, 'the same cycle counter');
	is($replayed->result->reason, $original->result->reason, 'the same reason');
	is_deeply($replayed->captured, $original->captured, 'and the same score');
	is($replayed->to_text, $original->to_text, 'the transcripts agree');
};

subtest 'a transcript round trips through the game' => sub {
	my $original = played(12);
	my $text = $original->to_text;

	cmp_ok(length $text, '>', 8, 'there is a transcript');

	my $from = Game::Oware->from_text($text, seed => 'x' x 32);

	is_deeply($from->board, $original->board, 'it plays back to the same board');
	is($from->to_text, $text, 'and writes the same transcript');
};

subtest 'a forged capture is refused' => sub {
	my $original = played(12);
	my $log = $original->events;

	my ($sow) = grep { $_->{kind} eq 'sow' } @$log;
	$sow->{payload}{taken} = 40;

	eval { Game::Oware->new(seed => 'x' x 32)->replay($log) };
	like($@, qr/does not replay to itself/,
		'the engine recomputes what the move took and refuses the claim');
};

subtest 'a forged house is refused' => sub {
	my $original = played(12);
	my $log = $original->events;

	my @sows = grep { $_->{kind} eq 'sow' } @$log;
	$sows[-1]->{payload}{house} = $sows[-1]->{payload}{house} == 0 ? 1 : 0;

	eval { Game::Oware->new(seed => 'x' x 32)->replay($log) };
	ok($@, 'a move that was not the move played is refused');
};

subtest 'a forged ending is refused' => sub {
	my $original = played(12);
	my $log = $original->events;

	push @$log, {
		actor   => 'sys',
		kind    => 'sweep',
		payload => { p => 'p1', why => 'no_feed' },
	};

	eval { Game::Oware->new(seed => 'x' x 32)->replay($log) };
	like($@, qr/does not replay to itself/,
		'a sweep at a position where moves existed awards a whole board and is refused');
};

subtest 'a forged cycle is refused' => sub {
	my $original = played(12);
	my $log = $original->events;

	push @$log, {
		actor   => 'sys',
		kind    => 'cycle',
		payload => { why => 'plies', plies => 50 },
	};

	eval { Game::Oware->new(seed => 'x' x 32)->replay($log) };
	like($@, qr/does not replay to itself/,
		'a cycle before the counter reached the cut is refused');
};

subtest 'a log from another variant is refused' => sub {
	my $original = played(12);

	eval {
		Game::Oware->new(seed => 'x' x 32, variant => 'awari')
			->replay($original->events);
	};
	like($@, qr/made under a different variant/, 'the rules the log was made under matter');
};

subtest 'a log that does not open with a start is refused' => sub {
	my $original = played(12);
	my $log = $original->events;
	shift @$log;

	eval { Game::Oware->new(seed => 'x' x 32)->replay($log) };
	like($@, qr/does not open with a start/, 'refused');
};

subtest 'a log that began from a different position is refused' => sub {
	my $original = played(12);

	eval {
		Game::Oware->new(seed => 'x' x 32,
			board => [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 18, 18 ])
			->replay($original->events);
	};
	like($@, qr/began from a different position/, 'refused');
};

subtest 'replay refuses a game that has already been played' => sub {
	my $original = played(12);
	my $g = Game::Oware->new(seed => 'x' x 32);
	$g->play('p1', 0);

	eval { $g->replay($original->events) };
	like($@, qr/wants a game that has not been played/, 'refused');
};

subtest 'timeout and abandon are applied from the log, because the board cannot say' => sub {
	my $g = played(8);
	$g->timeout('p1');

	my $replayed = Game::Oware->new(seed => 'x' x 32)->replay($g->events);

	is($replayed->status, 'finished', 'the clock ran out in the replay too');
	is($replayed->winner, 'p2', 'and the same seat won');
	is($replayed->result->result, 'timeout', 'with the same token');
	is($replayed->result->score, undef, 'and no official score');
};

subtest 'a resignation replays' => sub {
	my $g = played(6);
	$g->resign('p2');

	my $replayed = Game::Oware->new(seed => 'x' x 32)->replay($g->events);

	is($replayed->winner, 'p1', 'the other seat won');
	is($replayed->result->result, 'resign', 'by resignation');
};

subtest 'clone plays on independently' => sub {
	my $g = played(10);
	my $copy = $g->clone;

	my ($seat) = $g->waiting_on;
	my $house = $g->legal($seat)->[0];
	$copy->play($seat, $house);

	isnt(join(',', @{ $copy->board }), join(',', @{ $g->board }),
		'the copy moved and the original did not');
	is(scalar @{ $g->events } + 1, scalar @{ $copy->events },
		'and the logs diverged rather than being shared');
};

done_testing;
