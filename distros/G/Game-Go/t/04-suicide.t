#!perl

# Suicide is forbidden, and the ORDER of the two rules that decide it.
#
# Article 4 says a group exists only while it has a liberty, and Article 5 says
# the opposing stones come off first:
#
#   If, due to a player's move, one or more of his opponent's stones cannot
#   exist on the board according to the preceding article, the player must
#   remove all these opposing stones, which are called "prisoners." In this
#   case, the move is completed when the stones have been removed.
#
# So A MOVE THAT CAPTURES IS NEVER SUICIDE, and the whole point of this file is
# the pair of subtests where the SAME POINT is suicide in one position and a
# capture in the other. Testing suicide before capture is the commonest way a
# first Go engine is wrong, and it is wrong in the way that is hardest to
# notice: a lone captured stone leaves an empty point behind it, so every
# capture-the-lone-stone test still passes and only captures into a filled
# shape fail.

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Engine;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

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

subtest 'a single stone into a surrounded point is suicide' => sub {
	# (2,1) has four white neighbours and every one of them is healthy:
	#
	#        col: 0  1  2  3  4
	#     row 0:  .  .  O  .  .
	#     row 1:  .  O  .  O  .
	#     row 2:  .  .  O  .  .
	#
	# White (1,1) -> (0,1), (1,0), (1,2) and (2,1) all empty: FOUR liberties,
	# so nothing dies. Black at (2,1) would have no liberty of its own and
	# nothing would come off, so it is refused.
	#
	# (2,0) is the one to be careful about, and getting it wrong here is what
	# this comment is for: it sits on the TOP EDGE, so its fourth neighbour is
	# the sentinel ring and it has THREE liberties, not four. The first draft
	# of this test said four by waving at "the other three", and the engine
	# was right.
	my $b = board(9, <<'POS');
		. . O . .
		. O . O .
		. . O . .
POS

	is($b->libs($b->point_of(1, 1)), 4, 'the white stone left of the point has four liberties');
	is($b->libs($b->point_of(2, 2)), 4, 'the one below it has four');
	is($b->libs($b->point_of(2, 0)), 3, 'and the one on the top edge has three');

	is($b->legal($b->point_of(2, 1), $B), Game::Go::ILL_SUICIDE,
		'so black at the middle is suicide');

	my $r = $b->play($b->point_of(2, 1), $B);
	is($r->{code}, Game::Go::ILL_SUICIDE, 'and the play is refused');
	is($r->{message}, 'that move would leave your own stones with no liberty',
		'with the sentence a player is shown');
	is($b->at($b->point_of(2, 1)), Game::Go::EMPTY, 'the point is still empty');
	is($b->stones($B), 0, 'and no black stone was counted');

	# White may of course play there: it joins four of its own stones.
	ok($b->is_legal($b->point_of(2, 1), $W), 'white may play the same point');
	done_testing();
};

subtest 'THE SAME POINT is legal when it captures' => sub {
	# The position above, with black stones added so that white (1,1) has
	# exactly one liberty, which is the contested point:
	#
	#        col: 0  1  2  3  4
	#     row 0:  .  X  O  .  .
	#     row 1:  X  O  .  O  .
	#     row 2:  .  X  O  .  .
	#
	# White (1,1) -> (0,1) black, (1,0) black, (1,2) black, (2,1) EMPTY.
	# Exactly one liberty, so black at (2,1) takes it, and the point white
	# vacates is black's liberty. Article 5's order is the whole difference
	# between this subtest and the one above.
	my $b = board(9, <<'POS');
		. X O . .
		X O . O .
		. X O . .
POS

	is($b->libs($b->point_of(1, 1)), 1, 'white (1,1) is down to one liberty');
	is($b->chain_size($b->point_of(1, 1)), 1, 'and is a lone stone');

	is($b->legal($b->point_of(2, 1), $B), Game::Go::OK,
		'so black at the middle is LEGAL, where the same point was suicide above');

	my $r = $b->play($b->point_of(2, 1), $B);
	ok($r->{ok}, 'and the play goes through');
	is_deeply($r->{caps}, [ $b->point_of(1, 1) ], 'capturing exactly white (1,1)');
	is($b->at($b->point_of(1, 1)), Game::Go::EMPTY, 'the white stone is off');

	# The capturing stone now breathes through the point it emptied, and
	# through nothing else: (3,1), (2,0) and (2,2) are all white.
	is($b->libs($b->point_of(2, 1)), 1, 'and the new stone has the one liberty it made');

	# Which means all three of Article 6's clauses hold, so this capture is
	# also a ko. Asserted because it is a consequence rather than a design,
	# and a reader is entitled to see that the two rules compose.
	is($b->ko_point, $b->point_of(1, 1), 'and this capture happens to make a ko');
	is($b->ko_colour, $W, 'forbidden to white');
	done_testing();
};

subtest 'a multi-stone suicide is refused too' => sub {
	# Black (1,1) has one liberty, (1,0), and (1,0) is itself walled in:
	#
	#        col: 0  1  2
	#     row 0:  O  .  O
	#     row 1:  O  X  O
	#     row 2:  .  O  .
	#
	# Black plays (1,0), joining (1,1) into a chain of two. That chain's
	# points:
	#   (1,0) -> (0,0) white, (2,0) white, ring above, (1,1) own : nothing
	#   (1,1) -> (0,1) white, (2,1) white, (1,0) own, (1,2) white: nothing
	# No liberty. And nothing dies to it: white (0,0)+(0,1) still has (0,2),
	# white (2,0)+(2,1) still has (3,0) and more, white (1,2) has (0,2) and
	# (1,3). So the move is refused, and it is refused for a chain of two
	# rather than for the played stone alone.
	my $b = board(9, <<'POS');
		O . O
		O X O
		. O .
POS

	is($b->libs($b->point_of(1, 1)), 1, 'the black stone has one liberty');
	cmp_ok($b->libs($b->point_of(0, 0)), '>', 1, 'and no white chain is in atari');
	cmp_ok($b->libs($b->point_of(2, 0)), '>', 1, '...');
	cmp_ok($b->libs($b->point_of(1, 2)), '>', 1, '...');

	is($b->legal($b->point_of(1, 0), $B), Game::Go::ILL_SUICIDE,
		'so filling its own last liberty is suicide');

	my $r = $b->play($b->point_of(1, 0), $B);
	is($r->{code}, Game::Go::ILL_SUICIDE, 'refused');
	is($b->stones($B), 1, 'and the one black stone it had is all it has');
	done_testing();
};

subtest 'Tromp-Taylor would allow all of that, and we do not' => sub {
	# Written down where it is implemented rather than left to be found. Our
	# refusal follows the Japanese rules of 1989, Article 4, and the British
	# Go Association's comparison table lists Japanese and Korean as the
	# rulesets that refuse suicide. TROMP-TAYLOR PERMITS IT: its rule 7
	# clears the opponent's colour and THEN one's own, so a play that kills
	# only its own stones is legal there and they come straight off.
	#
	# A reader comparing this engine against a Tromp-Taylor reference will
	# find this difference first, so the code path has a test naming it.
	my $b = board(9, <<'POS');
		. . O . .
		. O . O .
		. . O . .
POS
	is($b->legal($b->point_of(2, 1), $B), Game::Go::ILL_SUICIDE,
		'this engine refuses it; a Tromp-Taylor engine would play it and lift the stone');
	done_testing();
};

subtest 'a position where the only legal move is a capture' => sub {
	# A 2x2 board is the smallest thing the engine accepts and it makes this
	# easy to state exhaustively. White holds three of the four points:
	#
	#        col: 0  1
	#     row 0:  O  O
	#     row 1:  O  .
	#
	# The white chain of three has exactly one liberty, (1,1). Black at (1,1)
	# captures all three. It is black's ONLY legal move, because it is the
	# only empty point; and it is legal only because of Article 5's order,
	# since black alone at (1,1) on a filled board would have no liberty.
	my $b = board(2, <<'POS');
		O O
		O .
POS

	is($b->chain_size($b->point_of(0, 0)), 3, 'white holds three points as one chain');
	is($b->libs($b->point_of(0, 0)), 1, 'with one liberty');

	my $moves = $b->legal_moves($B);
	is(scalar @$moves, 1, 'black has exactly one legal move');
	is($moves->[0], $b->point_of(1, 1), 'and it is the capture');

	my $r = $b->play($b->point_of(1, 1), $B);
	ok($r->{ok}, 'which goes through');
	is(scalar @{ $r->{caps} }, 3, 'taking all three white stones');
	is($b->stones($W), 0, 'white is off the board');
	is($b->stones($B), 1, 'and black has the one stone');

	# Three stones came off, so clause one of Article 6 refuses a ko.
	is($b->ko_point, -1, 'a three-stone capture is not a ko');
	done_testing();
};

subtest 'legal_moves never offers a suicide' => sub {
	# The cheap way to get this wrong is for legal_moves to test emptiness and
	# nothing else, which would be right about most of the board and wrong
	# about exactly the interesting point.
	my $b = board(9, <<'POS');
		. . O . .
		. O . O .
		. . O . .
POS

	my $moves = $b->legal_moves($B);
	my %legal = map { $_ => 1 } @$moves;

	ok(!$legal{ $b->point_of(2, 1) }, 'the suicide point is not offered to black');
	ok(scalar(@$moves) > 70, 'while the rest of the board is (' . scalar(@$moves) . ' points)');

	# And every point it DOES offer is really legal, checked one at a time
	# rather than trusted, with the count asserted so an empty list cannot
	# pass this.
	my $checked = 0;
	for my $pt (@$moves) {
		is($b->legal($pt, $B), Game::Go::OK, "offered point $pt is legal") if $checked < 3;
		$checked++ if $b->legal($pt, $B) == Game::Go::OK;
	}
	is($checked, scalar @$moves, 'every offered point verifies as legal');

	# White is offered the middle, because for white it joins four stones.
	my %wlegal = map { $_ => 1 } @{ $b->legal_moves($W) };
	ok($wlegal{ $b->point_of(2, 1) }, 'and white IS offered it');
	done_testing();
};

done_testing();
