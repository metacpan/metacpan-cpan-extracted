#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;

# Replay, and refusing a log that records something this engine would not have
# produced.
#
# ONLY THE PLAYER EVENTS ARE APPLIED. Every sys event is regenerated from the
# position and the whole log is then required to match what was handed in. That
# is what makes a forged one impossible to sneak through, and it is why there is
# no list here of "the sys events we check": they are all checked, by being
# rebuilt.
#
# A FORGED PASS IS THE CHEAPEST POSSIBLE CHEAT IN THIS GAME. A pass hands the
# opponent's turn back to you, so a log claiming one at a position where that
# seat could have moved is worth more than a tampered square. It is the first
# thing tried below.

my $B = 'Game::Reversi::Board';

sub sq { return $B->square_of(split //, $_[0]) }

# A whole game, and its log. The historic opening taking the lowest numbered
# legal square reaches a position where a turn is really forfeited, which is
# what the removed-pass case needs.
sub a_game {
	my ($variant) = @_;
	my $game = Game::Reversi->new(variant => $variant || 'historic');
	while ($game->status eq 'active') {
		my $legal = $game->legal($game->turn);
		last unless @$legal;
		$game->play($game->turn, $legal->[0]->square);
	}
	return $game;
}

# Written as a plain loop rather than a map. The obvious spelling,
#
#     map { my $e = $_; { %$e, payload => {...} } } @$log
#
# does not do what it looks like: the inner brace opens a BLOCK rather than an
# anonymous hash, so the map returns a flat list of keys and values and the
# arrayref ends up full of strings. The symptom arrives later and elsewhere, as
# "Can't use string ("actor") as a HASH ref".
sub deep_copy {
	my ($log) = @_;
	my @copy;
	for my $event (@$log) {
		my %payload;
		for my $key (keys %{ $event->{payload} }) {
			my $value = $event->{payload}{$key};
			$payload{$key} = ref $value eq 'ARRAY' ? [ @$value ] : $value;
		}
		push @copy, { %$event, payload => \%payload };
	}
	return \@copy;
}

sub fresh { return Game::Reversi->new(variant => $_[0] || 'historic') }

subtest 'a log replays to the same game' => sub {
	my $played = a_game('historic');
	my $log = $played->events;
	cmp_ok(scalar @$log, '>', 30, 'there is a log to replay');

	my $replayed = fresh('historic');
	ok(eval { $replayed->replay($log); 1 }, 'it replays') or diag $@;

	is_deeply($replayed->board, $played->board, 'to the same board');
	is($replayed->status, $played->status, 'the same status');
	is($replayed->turn, $played->turn, 'the same turn');
	is($replayed->winner, $played->winner, 'the same winner');
	is_deeply($replayed->counts, $played->counts, 'the same counts');
	is_deeply($replayed->events, $log, 'and to the same log, event for event');
	is($replayed->to_text, $played->to_text, 'and the same transcript');
	done_testing();
};

subtest 'the othello variant replays too' => sub {
	my $played = a_game('othello');
	my $replayed = fresh('othello');
	ok(eval { $replayed->replay($played->events); 1 }, 'it replays') or diag $@;
	is_deeply($replayed->board, $played->board, 'to the same board');
	done_testing();
};

# ---- the forged pass ---------------------------------------------------------

subtest 'a log claiming a pass that never happened is refused' => sub {
	# The cheapest cheat: a pass hands the opponent's turn back to you. Insert
	# one after a move, at a position where the other seat certainly could have
	# played, and the engine must refuse the whole log.
	my $played = a_game('historic');
	my $log = deep_copy($played->events);

	# After the opening, so the position is a real one with moves in it.
	my ($first_play) = grep { $log->[$_]{kind} eq 'play' } 0 .. $#$log;
	splice @$log, $first_play + 1, 0,
		{ actor => 'sys', kind => 'pass', payload => { colour => 'w' } };

	my $replayed = fresh('historic');
	ok(!eval { $replayed->replay($log); 1 }, 'the forged pass is refused');
	like($@, qr/does not replay/, 'saying the log records something we would not produce');
	done_testing();
};

subtest 'a log with a real pass quietly removed is refused too' => sub {
	# The mirror of the forgery, and it matters just as much: dropping a pass
	# makes the moves after it look as though they alternated, which changes who
	# played what.
	my $played = a_game('historic');
	my $log = deep_copy($played->events);
	my ($pass) = grep { $log->[$_]{kind} eq 'pass' } 0 .. $#$log;

	ok(defined $pass, 'this game really does forfeit a turn') or do {
		done_testing();
		return;
	};

	splice @$log, $pass, 1;
	my $replayed = fresh('historic');
	ok(!eval { $replayed->replay($log); 1 }, 'the missing pass is refused');
	like($@, qr/does not replay/, 'for the same reason');
	done_testing();
};

# ---- tampering with the moves themselves -------------------------------------

subtest 'a move changed to an illegal square is refused' => sub {
	my $played = a_game('historic');
	my $log = deep_copy($played->events);
	my ($i) = grep { $log->[$_]{kind} eq 'play' } 0 .. $#$log;

	# a1 is a corner and cannot possibly be legal on the fifth ply.
	$log->[$i]{payload}{square} = sq('a1');

	my $replayed = fresh('historic');
	ok(!eval { $replayed->replay($log); 1 }, 'refused');
	like($@, qr/does not replay/, 'saying so');
	done_testing();
};

subtest 'a move changed to a different LEGAL square is refused as well' => sub {
	# The harder case, and the one a naive replay lets through: the substituted
	# move is playable, so applying it succeeds and the game carries on. What
	# gives it away is that the log records what each move turned, and a
	# different square turns different discs.
	my $played = a_game('historic');
	my $log = deep_copy($played->events);

	# Find a play where the mover had a choice, and swap in one of the others.
	my $replayed = fresh('historic');
	my ($swapped, $board, $colour) = (0);
	my $probe = fresh('historic');
	for my $i (0 .. $#$log) {
		my $event = $log->[$i];
		next if $event->{actor} eq 'sys';
		my $legal = $probe->legal($event->{actor});
		if (!$swapped && @$legal > 1) {
			my ($other) = grep { $_->square != $event->{payload}{square} } @$legal;
			$probe->play($event->{actor}, $event->{payload}{square});
			$log->[$i]{payload}{square} = $other->square;
			$swapped = 1;
			next;
		}
		$probe->play($event->{actor}, $event->{payload}{square});
	}
	ok($swapped, 'found a move where the player had a choice') or do {
		done_testing();
		return;
	};

	ok(!eval { $replayed->replay($log); 1 },
		'a different legal square is still refused, because the recorded flips no longer match');
	like($@, qr/does not replay/, 'saying so');
	done_testing();
};

subtest 'a move attributed to the wrong seat is refused' => sub {
	my $played = a_game('historic');
	my $log = deep_copy($played->events);
	my ($i) = grep { $log->[$_]{actor} eq 'b' } 0 .. $#$log;
	$log->[$i]{actor} = 'w';

	my $replayed = fresh('historic');
	ok(!eval { $replayed->replay($log); 1 }, 'refused');
	like($@, qr/does not replay|not_your_turn/, 'as a move out of turn');
	done_testing();
};

# ---- the log's own shape -----------------------------------------------------

subtest 'a log without its start is refused' => sub {
	my $played = a_game('historic');
	my $log = deep_copy($played->events);
	shift @$log;

	my $replayed = fresh('historic');
	ok(!eval { $replayed->replay($log); 1 }, 'refused');
	like($@, qr/does not open with a start/, 'saying what is missing');
	done_testing();
};

subtest 'a log from the other variant is refused' => sub {
	my $played = a_game('othello');
	my $replayed = fresh('historic');
	ok(!eval { $replayed->replay($played->events); 1 },
		'an othello log does not replay into a historic game');
	like($@, qr/different variant/, 'saying so, rather than failing move by move');
	done_testing();
};

subtest 'a log cannot be replayed into a game already under way' => sub {
	my $played = a_game('historic');
	my $started = fresh('historic');
	$started->play($started->turn, $started->legal($started->turn)->[0]->square);

	ok(!eval { $started->replay($played->events); 1 },
		'replaying into a game with moves in it is refused');
	like($@, qr/has not been played/, 'saying why');

	ok(!eval { fresh('historic')->replay('not a log'); 1 },
		'and a log that is not an arrayref is refused');
	done_testing();
};

done_testing();
