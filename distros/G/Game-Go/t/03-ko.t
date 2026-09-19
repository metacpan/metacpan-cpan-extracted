#!perl

# Article 6, the ko rule, and the three clauses that decide whether a move made
# a ko at all.
#
# EVERY POSITION HERE IS DRAWN AND EVERY EXPECTATION DERIVED IN A COMMENT
# BESIDE IT. Article 6 describes a SHAPE, not a procedure:
#
#   A shape in which the players can alternately capture and recapture one
#   opposing stone is called a "ko." A player whose stone has been captured in
#   a ko cannot recapture in that ko on the next move.
#
# So the question after every capture is whether THIS move made that shape, and
# three things must all hold. There is one subtest per clause, each built so
# that exactly one clause is the thing saying no.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Engine;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

# Places stones with `put`, which judges nothing, so a position cannot be
# built by the rules under test. Row 0 is the top. X black, O white.
sub board {
	my ($size, $diagram) = @_;
	my $b = Game::Go::Engine->new(size => $size);
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

subtest 'the textbook ko, and the recapture it forbids' => sub {
	# White (2,1) has exactly one liberty, (1,1), and black surrounds the
	# point black will play from every other side:
	#
	#        col: 0  1  2  3
	#     row 0:  .  O  X  .
	#     row 1:  O  .  O  X
	#     row 2:  .  O  X  .
	#
	# White (2,1) liberties: (1,1) empty, (3,1) black, (2,0) black,
	# (2,2) black. Exactly one, so black playing (1,1) takes it.
	my $b = board(9, <<'POS');
		. O X .
		O . O X
		. O X .
POS

	is($b->libs($b->point_of(2, 1)), 1, 'the white stone has one liberty');
	is($b->chain_size($b->point_of(2, 1)), 1, 'and it is a lone stone');
	is($b->ko_point, -1, 'a hand-built position has no ko');

	my $r = $b->play($b->point_of(1, 1), $B);
	ok($r->{ok}, 'black plays the capture');
	is_deeply($r->{caps}, [ $b->point_of(2, 1) ], 'taking exactly the white stone');

	# Black (1,1) is now a lone stone whose neighbours are (0,1) white,
	# (1,0) white, (1,2) white and (2,1) empty: size 1, one liberty. All
	# three clauses hold, so this is a ko and the point is the one the white
	# stone came off.
	is($b->chain_size($b->point_of(1, 1)), 1, 'the capturing stone is alone');
	is($b->libs($b->point_of(1, 1)), 1, 'with one liberty');
	is($b->ko_point, $b->point_of(2, 1), 'so the ko point is where white was');
	is($r->{ko_point}, $b->point_of(2, 1), 'and the play reported it');

	# Article 6: not on the next move.
	is($b->legal($b->point_of(2, 1), $W), Game::Go::ILL_KO,
		'white may not recapture immediately');
	ok(!$b->is_legal($b->point_of(2, 1), $W), 'is_legal agrees');

	my $refused = $b->play($b->point_of(2, 1), $W);
	is($refused->{code}, Game::Go::ILL_KO, 'and the play is refused');
	is($refused->{message}, 'the ko rule forbids retaking that point immediately',
		'with the sentence a player is shown');
	is(scalar @{ $refused->{caps} }, 0, 'nothing was captured');

	# A REFUSED PLAY MUST LEAVE THE BOARD ALONE, or a client that retries
	# after a refusal plays into a position nobody has seen.
	is($b->at($b->point_of(1, 1)), $B, 'the board is untouched: black still there');
	is($b->at($b->point_of(2, 1)), Game::Go::EMPTY, 'and the ko point still empty');
	is($b->stones($B), 4, 'with the stone counts unchanged');
	is($b->stones($W), 3, '...');

	# A KO FORBIDS ITS POINT TO ONE COLOUR, AND ARTICLE 6 NAMES WHICH:
	# "A player WHOSE STONE HAS BEEN CAPTURED in a ko cannot recapture in
	# that ko on the next move." White lost the stone, so white is refused.
	# Black is not, and on a filled board black sometimes wants to play there
	# to connect. Refusing both colours is the easy version of this rule and
	# it refuses a legal move; the engine did exactly that until this test
	# said otherwise.
	is($b->ko_colour, $W, 'the ko names white as the player it forbids');
	ok(!$b->is_legal($b->point_of(2, 1), $W), 'so white is refused');
	ok($b->is_legal($b->point_of(2, 1), $B), 'and black is not');
	done_testing();
};

subtest 'the ko point is cleared by any other move' => sub {
	my $b = board(9, <<'POS');
		. O X .
		O . O X
		. O X .
POS
	$b->play($b->point_of(1, 1), $B);
	is($b->ko_point, $b->point_of(2, 1), 'a ko is standing');

	# "On the next move" is the whole of it: white plays somewhere else, and
	# by the time the recapture comes round again it is not the next move.
	my $away = $b->play($b->point_of(7, 7), $W);
	ok($away->{ok}, 'white plays away');
	is($b->ko_point, -1, 'which clears the ko');

	# Black now has to deal with it, which is what a ko fight is.
	ok($b->is_legal($b->point_of(2, 1), $W), 'and the recapture is legal again')
		or diag Game::Go::refusal($b->legal($b->point_of(2, 1), $W));
	done_testing();
};

subtest 'a pass clears the ko too' => sub {
	# Article 6 forbids the recapture on the NEXT move only, and after a pass
	# the recapture is the move after that. An engine that let a pass hold the
	# ko open would make passing a way to keep a point frozen.
	my $b = board(9, <<'POS');
		. O X .
		O . O X
		. O X .
POS
	$b->play($b->point_of(1, 1), $B);
	is($b->ko_point, $b->point_of(2, 1), 'a ko is standing');

	$b->pass($W);
	is($b->ko_point, -1, 'white passing clears it');
	ok($b->is_legal($b->point_of(2, 1), $W), 'and the point is playable');
	done_testing();
};

subtest 'clause one: capturing two stones is not a ko' => sub {
	# A white chain of two with a single shared liberty at (3,0):
	#
	#        col: 0  1  2  3
	#     row 0:  X  O  O  .
	#     row 1:  .  X  X  .
	#
	# White (1,0)+(2,0) liberties:
	#   (1,0) -> (0,0) black, (2,0) own, ring above, (1,1) black : nothing
	#   (2,0) -> (1,0) own, (3,0) EMPTY, ring above, (2,1) black : (3,0)
	# Exactly one, so black at (3,0) takes both.
	my $b = board(9, <<'POS');
		X O O .
		. X X .
POS

	is($b->chain_size($b->point_of(1, 0)), 2, 'the white chain is two stones');
	is($b->libs($b->point_of(1, 0)), 1, 'with one liberty between them');

	my $r = $b->play($b->point_of(3, 0), $B);
	ok($r->{ok}, 'black captures');
	is(scalar @{ $r->{caps} }, 2, 'two stones come off');

	# Clause one refuses before the other two are even looked at. Without it
	# a two-stone capture would set a phantom ko and refuse the opponent a
	# point Article 6 says nothing about.
	is($b->ko_point, -1, 'and there is no ko');
	is($b->stones($W), 0, 'white has nothing left on the board');
	done_testing();
};

subtest 'clause two: a capture that joins a bigger chain is not a ko' => sub {
	# White (2,0) has one liberty, (1,0). Black playing (1,0) captures it AND
	# joins the black chain already at (1,1)+(2,1):
	#
	#        col: 0  1  2  3
	#     row 0:  .  .  O  X
	#     row 1:  .  X  X  .
	#
	# White (2,0) -> (1,0) EMPTY, (3,0) black, ring above, (2,1) black : one.
	my $b = board(9, <<'POS');
		. . O X
		. X X .
POS

	is($b->libs($b->point_of(2, 0)), 1, 'the white stone has one liberty');

	my $r = $b->play($b->point_of(1, 0), $B);
	ok($r->{ok}, 'black captures it');
	is(scalar @{ $r->{caps} }, 1, 'exactly one stone, so clause one passes');

	# Clause two is the one that says no: the capturing stone is part of a
	# chain of three, and no shape that can repeat has been made.
	is($b->chain_size($b->point_of(1, 0)), 3, 'but the capturing stone is in a chain of three');
	is($b->ko_point, -1, 'so there is no ko');
	done_testing();
};

subtest 'clause three: a capture that leaves room is not a ko' => sub {
	# Same lone white stone with one liberty, but this time the point black
	# plays has empty space around it:
	#
	#        col: 0  1  2  3
	#     row 0:  .  .  O  X
	#     row 1:  .  .  X  .
	#
	# White (2,0) -> (1,0) EMPTY, (3,0) black, ring above, (2,1) black : one.
	# Black (1,0) afterwards -> (0,0) empty, (2,0) now empty, ring above,
	# (1,1) empty : THREE liberties, and it is alone.
	my $b = board(9, <<'POS');
		. . O X
		. . X .
POS

	is($b->libs($b->point_of(2, 0)), 1, 'the white stone has one liberty');

	my $r = $b->play($b->point_of(1, 0), $B);
	ok($r->{ok}, 'black captures it');
	is(scalar @{ $r->{caps} }, 1, 'one stone, so clause one passes');
	is($b->chain_size($b->point_of(1, 0)), 1, 'the capturing stone is alone, so clause two passes');

	# Clause three is the one that says no. Without it the engine would set a
	# ko where no recapture was ever possible, and the symptom is the worst of
	# the three to debug: a legal move refused somewhere apparently
	# unrelated, three moves later.
	is($b->libs($b->point_of(1, 0)), 3, 'but it has three liberties');
	is($b->ko_point, -1, 'so there is no ko');
	done_testing();
};

subtest 'a ko is per point, not a mode the board is in' => sub {
	my $b = board(9, <<'POS');
		. O X .
		O . O X
		. O X .
POS
	$b->play($b->point_of(1, 1), $B);

	# Only the one point is forbidden. Everything else white could do it
	# still can, which matters because a ko fight is played by making the
	# opponent answer somewhere else.
	my $moves = $b->legal_moves($W);
	my %legal = map { $_ => 1 } @$moves;
	ok(!$legal{ $b->point_of(2, 1) }, 'the ko point is not in white legal moves');
	ok($legal{ $b->point_of(7, 7) }, 'a point far away is');
	ok(scalar(@$moves) > 70, 'and most of the board still is (' . scalar(@$moves) . ' points)');

	# Black is not affected at all.
	my $bmoves = $b->legal_moves($B);
	my %blegal = map { $_ => 1 } @$bmoves;
	ok($blegal{ $b->point_of(2, 1) }, 'and black may play the ko point');
	done_testing();
};

done_testing();
