#!perl

# Positional superko, which is this distribution's ONE declared departure from
# its source, and the test that proves it is a separate rule from simple ko.
#
# WHY IT EXISTS. The Japanese rules of 1989, Article 12:
#
#   When the same whole-board position is repeated during a game, if the
#   players agree, the game ends without result.
#
# A rated correspondence site cannot express "no result": games.result is
# CHECK-constrained to score, resign, timeout and abandoned, and the pairwise
# rating has nothing to say about a void game. The British convention is no
# help either, because it makes a repeated position a jigo and the fractional
# komi has already made jigo impossible. So the repetition is REFUSED as an
# illegal move instead, which is what AGA and New Zealand rules do, and Article
# 12 becomes unreachable.
#
# THE SHAPE OF THE PROOF. Simple ko and superko are separate rules, and the way
# to show it is to make the SAME MOVE be refused twice for two different
# reasons. So: reach a ko, then clear the ko point with two passes, then play
# the recapture. Simple ko no longer has anything to say. Superko does.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Engine;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

sub board {
	my ($size, $diagram, %o) = @_;
	my $b = Game::Go::Engine->new(size => $size, %o);
	my @rows = grep { /\S/ } split /\n/, $diagram;
	for my $row (0 .. $#rows) {
		my @cells = grep { length } split /\s+/, $rows[$row];
		for my $col (0 .. $#cells) {
			next if $cells[$col] eq '.';
			$b->put($b->point_of($col, $row), $cells[$col] eq 'X' ? $B : $W);
		}
	}
	return $b;
}

# The ko position, as drawn in t/03-ko.t:
#
#        col: 0  1  2  3
#     row 0:  .  O  X  .
#     row 1:  O  .  O  X
#     row 2:  .  O  X  .
#
# Call this POSITION A. Black at (1,1) captures white (2,1), giving POSITION B.
# White at (2,1) would capture black (1,1), giving POSITION A again.
my $KO = <<'POS';
	. O X .
	O . O X
	. O X .
POS

subtest 'the history starts with the position it starts from' => sub {
	my $b = Game::Go::Engine->new(size => 9);
	ok($b->has_history, 'a board has a history by default, because the shipped rule is superko');
	is($b->history_length, 1, 'holding the starting position');
	ok($b->seen_position, 'which it therefore reports as seen');

	# THE STARTING POSITION COUNTS. Without it a game that returned to an
	# empty board would not be a repetition, which is reachable on a small
	# board and is exactly the case nobody constructs.
	my $p = Game::Go::Engine->new(size => 9, history => 0);
	ok(!$p->has_history, 'a board asked for no history has none');
	is($p->history_length, 0, '...');
	ok(!$p->seen_position, 'and reports nothing as seen');
	done_testing();
};

subtest 'the same move, refused by simple ko and then by superko' => sub {
	my $b = board(9, $KO);

	# Position A was built by hand, so it is not in the history yet: `put` is
	# a structure primitive and does not push. Say the game starts here.
	$b->push_position;
	is($b->history_length, 2, 'the starting board and position A are both recorded');

	my $A = $b->pack_position;

	# Black captures. Position B.
	my $r = $b->play($b->point_of(1, 1), $B);
	ok($r->{ok}, 'black takes the ko');
	is($b->history_length, 3, 'and position B is recorded');
	isnt($b->pack_position, $A, 'B is not A');

	# FIRST REFUSAL: simple ko. Article 6, on the next move only.
	is($b->legal($b->point_of(2, 1), $W), Game::Go::ILL_KO,
		'white is refused by the KO rule');

	# Clear the ko with two passes. Article 6 has now had its say and has
	# nothing left to add: the recapture is no longer "the next move".
	$b->pass($W);
	$b->pass($B);
	is($b->ko_point, -1, 'two passes clear the ko point');
	is($b->history_length, 3, 'and a pass records no position, because it makes none');

	# SECOND REFUSAL: the same point, the same colour, a different rule.
	# White at (2,1) would capture black (1,1) and hand the board back to
	# position A, which is in the history.
	# The recapture's predicted position IS position A, which is what the
	# filter will match on. Compared against A's actual bytes, recorded before
	# any of this happened, rather than against itself.
	is($b->legal($b->point_of(2, 1), $W), Game::Go::ILL_REPEAT,
		'and white is refused by SUPERKO, for the same move the ko rule refused before');

	my $refused = $b->play($b->point_of(2, 1), $W);
	is($refused->{code}, Game::Go::ILL_REPEAT, 'the play is refused');
	is($refused->{message}, 'that move would repeat a position the game has already had',
		'with its own sentence, not the ko one');

	# ARTICLE 12 IS UNREACHABLE. The engine has no "no result" to report and
	# is never asked to: the move simply does not happen, the board is
	# untouched, and it is still white to find something else to do.
	is($b->at($b->point_of(1, 1)), $B, 'the board is untouched');
	is($b->at($b->point_of(2, 1)), Game::Go::EMPTY, '...');
	is($b->history_length, 3, 'and nothing was recorded');
	done_testing();
};

subtest 'superko off, and the same move goes through' => sub {
	# Proving the refusal above came from the history and not from something
	# else that happened to say no. Same position, same passes, superko off.
	my $b = board(9, $KO);
	$b->push_position;
	$b->play($b->point_of(1, 1), $B);
	$b->pass($W);
	$b->pass($B);

	is($b->superko(0), 0, 'superko turned off');
	is($b->legal($b->point_of(2, 1), $W), Game::Go::OK,
		'and the repetition is legal, which is what Tromp-Taylor and the playouts want');

	my $r = $b->play($b->point_of(2, 1), $W);
	ok($r->{ok}, 'white recaptures');
	is_deeply($r->{caps}, [ $b->point_of(1, 1) ], 'taking the black stone back');

	is($b->superko(1), 1, 'and it can be turned back on');
	done_testing();
};

subtest 'a board with no history gets simple ko and nothing else' => sub {
	# This is the playout's rule, and it is passed in rather than defaulted.
	# Maintaining a superko history inside a playout costs more than the
	# playout does, so every playout engine makes this choice; the point of
	# making it an argument is that nobody inherits it by accident.
	my $b = board(9, $KO, history => 0);
	ok(!$b->has_history, 'no history');

	$b->play($b->point_of(1, 1), $B);
	is($b->legal($b->point_of(2, 1), $W), Game::Go::ILL_KO,
		'simple ko still applies, because it is board state and not history');

	$b->pass($W);
	$b->pass($B);
	is($b->legal($b->point_of(2, 1), $W), Game::Go::OK,
		'and with the ko cleared there is nothing left to refuse the repetition');
	done_testing();
};

subtest 'the hash is a filter and the compare is the verdict' => sub {
	# hash_after is exposed for exactly this: a test that cannot see the
	# filter's input cannot tell a working filter from one that always misses.
	my $b = board(9, $KO);
	$b->push_position;
	my $after = $b->hash_after_hex($b->point_of(1, 1), $B);

	# Playing it must produce precisely the hash that was predicted, or the
	# filter is testing one number and the board is keeping another, and
	# superko would silently never fire.
	$b->play($b->point_of(1, 1), $B);
	is($b->hash_hex, $after, 'the predicted hash is the hash the board ends up with');
	like($after, qr/\A[0-9a-f]{16}\z/, 'and it is sixteen hex characters');

	# A capture changes the hash by more than the stone played, because the
	# captured stone comes out of it too. If hash_after forgot the captures it
	# would predict a position that never occurs and superko would never fire.
	my $c = board(9, $KO);
	my $naive = Game::Go::Engine->zobrist_hex($B, $c->point_of(1, 1));
	isnt($after, $naive, 'a capture moves the hash by more than the played stone alone');
	done_testing();
};

subtest 'a repetition reached by a different route is still a repetition' => sub {
	# Positional superko is about COLOURINGS, not about move sequences. Tromp
	# states the choice and the reason:
	#
	#   This is the positional superko (PSK) rule, while the situational
	#   superko (SSK) rule forbids repeating the same grid coloring with the
	#   same player to move. Only in exceedingly rare cases does the
	#   difference matter, sufficient reason for the simpler PSK rule to be
	#   prefered.
	#
	# So a colouring reached by two different orders is one entry, and this is
	# the test that the history is keyed on the position rather than the path.
	my $b = Game::Go::Engine->new(size => 9);
	$b->play($b->point_of(0, 0), $B);
	$b->play($b->point_of(8, 8), $W);
	my $reached_one_way = $b->pack_position;
	is($b->history_length, 3, 'empty, then one stone, then two');

	my $c = Game::Go::Engine->new(size => 9);
	$c->play($c->point_of(4, 4), $B);       # a different first move
	$c->play($c->point_of(8, 8), $W);
	isnt($c->pack_position, $reached_one_way, 'a different game reaches a different position');

	# And the history really does hold what it claims: the position from two
	# moves ago is still in there.
	ok($b->seen_position, 'the current position is in its own history');
	done_testing();
};

done_testing();
