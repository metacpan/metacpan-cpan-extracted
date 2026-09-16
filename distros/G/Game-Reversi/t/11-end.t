#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi;
use Game::Reversi::Board;

# How a game ends, and the invariants that hold over whole games.
#
# The games below are played by this engine, so their SCORES are not evidence of
# anything and are never asserted. What is asserted is either an invariant that
# holds whatever the moves were, or a property derived on paper beforehand.

my $B = 'Game::Reversi::Board';

sub sq { return $B->square_of(split //, $_[0]) }

# Play a whole game, choosing the nth legal move each turn by a fixed rule.
sub play_out {
	my (%o) = @_;
	my $game = Game::Reversi->new(variant => $o{variant} || 'othello');
	my $pick = $o{pick} || sub { 0 };
	my $n = 0;
	while ($game->status eq 'active') {
		my $legal = $game->legal($game->turn);
		last unless @$legal;
		$game->play($game->turn, $legal->[ $pick->($n, scalar @$legal) ]->square);
		$n++;
	}
	return $game;
}

subtest 'a game finishes, and when it does neither side can move' => sub {
	for my $variant (qw(historic othello)) {
		my $game = play_out(variant => $variant);
		is($game->status, 'finished', "$variant: the game finished");
		is($game->turn, undef, "$variant: with nobody to move");
		is_deeply($game->legal('b'), [], "$variant: and nothing offered to Black");
		is_deeply($game->legal('w'), [], "$variant: nor to White");

		# WOF rule 8, which is the only end condition there is.
		ok(!$B->has_move($game->board, 'b'), "$variant: Black really cannot move");
		ok(!$B->has_move($game->board, 'w'), "$variant: nor can White");

		# Every disc is one colour or the other, and none went missing.
		my $count = $game->counts;
		is($count->{b} + $count->{w}, 64 - $B->empties($game->board),
			"$variant: the discs counted are the discs on the board");
	}
	done_testing();
};

subtest 'the last event is the end, and it names the winner' => sub {
	my $game = play_out(variant => 'historic');
	my @log = @{ $game->events };

	is($log[0]{kind}, 'start', 'the log opens with the start');
	is($log[0]{payload}{variant}, 'historic', 'naming the variant');
	is($log[0]{payload}{first}, 'b', 'and who moves first');

	is($log[-1]{actor}, 'sys', 'the log closes with a sys event');
	is($log[-1]{kind}, 'game_end', 'which is the end');
	is($log[-1]{payload}{winner}, $game->winner, 'and it names the winner');

	# Nothing is emitted after the end.
	$game->play('b', sq('a1'));
	$game->pass('b');
	is(scalar @{ $game->events }, scalar @log,
		'a refused move after the end adds nothing to the log');
	done_testing();
};

subtest 'the winner is whoever has more discs, and a tie is undef' => sub {
	for my $variant (qw(historic othello)) {
		my $game = play_out(variant => $variant);
		my $count = $game->counts;
		my $expect = $count->{b} == $count->{w} ? undef
		           : $count->{b} > $count->{w} ? 'b' : 'w';
		is($game->winner, $expect, "$variant: the winner follows the disc count");
	}
	done_testing();
};

# ---- a property derived on paper --------------------------------------------

subtest 'the two mirror strategies play mirror games and tie on score' => sub {
	# DERIVED, NOT OBSERVED, and it is the only check in this file that could
	# catch a lopsided engine.
	#
	# The Othello start is invariant under a half turn of the board: the map
	# (row, col) -> (7 - row, 7 - col) sends d5 to e4 and e5 to d4, and both of
	# those pairs hold the same colour. On a flat index that map is simply
	# i -> 63 - i.
	#
	# So consider two games from that position: one always playing its LOWEST
	# numbered legal square, the other always its HIGHEST. Reflection reverses
	# the ordering of the indices, so if the second board is always the
	# reflection of the first, the highest legal square of one is the reflection
	# of the lowest of the other. It is the reflection at the start, and the
	# step preserves it, so by induction the two games are reflections of each
	# other the whole way through.
	#
	# Two positions that are reflections have the same number of discs of each
	# colour. So the two games must finish with identical counts, and with
	# transcripts that are reflections square for square.
	#
	# An engine whose rays were not symmetric, say one diagonal walked wrongly,
	# would break this and almost nothing else would notice.
	my $low  = play_out(variant => 'othello', pick => sub { 0 });
	my $high = play_out(variant => 'othello', pick => sub { $_[1] - 1 });

	is_deeply($low->counts, $high->counts,
		'the two games finish with the same counts');
	is($low->winner, $high->winner, 'and the same winner');

	my @low_squares  = map { $_->{payload}{square} }
	                   grep { $_->{kind} eq 'play' } @{ $low->events };
	my @high_squares = map { $_->{payload}{square} }
	                   grep { $_->{kind} eq 'play' } @{ $high->events };
	is(scalar @low_squares, scalar @high_squares, 'the same number of moves');
	is_deeply([ map { 63 - $_ } @low_squares ], \@high_squares,
		'and every move of one is the reflection of the other, square for square');

	# The boards themselves, to be sure the reflection is of the position and
	# not only of the move list.
	my @reflected = reverse @{ $low->board };
	is_deeply(\@reflected, $high->board, 'the final boards are reflections too');
	done_testing();
};

# ---- both endings -----------------------------------------------------------

subtest 'a game can end with the board full' => sub {
	my $game = play_out(variant => 'othello');
	is($B->empties($game->board), 0, 'no square left empty');
	my $count = $game->counts;
	is($count->{b} + $count->{w}, 64, 'so all 64 discs are down');
	done_testing();
};

subtest 'and a game can end with squares still empty' => sub {
	# WOF rule 8's note: "It is possible for a game to end before all 64 squares
	# are filled." This finds such a game rather than asserting a particular one,
	# because which line of play reaches one is a fact about this engine.
	#
	# What matters is that the engine can reach that ending at all and handles
	# it: an engine that only ever ends on a full board would pass every other
	# test in this file.
	my ($found, $tried);
	for my $k (1 .. 500) {
		$tried = $k;
		my $game = play_out(variant => 'othello',
			pick => sub { ($k * 7 + $_[0] * 13) % $_[1] });
		next unless $B->empties($game->board);
		$found = $game;
		last;
	}

	ok($found, "a game ending with squares empty, found after $tried lines of play")
		or do { done_testing(); return };

	cmp_ok($B->empties($found->board), '>', 0, 'squares are still empty');
	is($found->status, 'finished', 'and the game is over anyway');
	ok(!$B->has_move($found->board, 'b'), 'because Black cannot move');
	ok(!$B->has_move($found->board, 'w'), 'and neither can White');

	my $count = $found->counts;
	cmp_ok($count->{b} + $count->{w}, '<', 64,
		'so fewer than 64 discs are down, which the scoring phase has to handle');
	done_testing();
};

done_testing();
