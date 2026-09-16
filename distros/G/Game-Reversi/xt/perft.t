#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Reversi::Board;
use Game::Reversi::Opening;

# The only exact, external check on move generation this distribution has.
#
# Counting the games reachable at each ply from a fixed position catches an
# off-by-one in a ray walk, a mishandled edge and a wrongly generated move all
# at once, and catches them as a WRONG NUMBER rather than as a plausible looking
# game. Everything else in the suite either derives a rule by hand or asserts an
# invariant over games this engine played; this one is checked against a figure
# nobody here computed.
#
# THE SOURCE, cited rather than generated:
#
#   OEIS A124004, "Number of possible Reversi games at the end of the n-th ply."
#   https://oeis.org/A124004
#   Alain Brobecker, 2006; terms to a(21) contributed by Paul Byrne and
#   Dominic Hofer. Fetched 15 Sep 2026.
#
#   Documentation of the sequence, including the starting position and how the
#   later terms were computed:
#   https://github.com/PanicSheep/ReversiPerftCUDA/blob/master/docs/A124004.md
#
# It runs from variant => 'othello', because that is the position the sequence
# starts from, and it is the whole reason this distribution carries the fixed
# opening at all. The historic opening reaches six positions and nobody has ever
# published a count for any of them.
#
# xt/ rather than t/: depth 8 takes about ten seconds and each further ply is
# roughly eight times the last, so nobody installing the module should pay for
# it.

unless ($ENV{RELEASE_TESTING} || $ENV{REVERSI_PERFT}) {
	plan skip_all => 'set RELEASE_TESTING or REVERSI_PERFT to run the perft ladder';
}

my $B = 'Game::Reversi::Board';

# A124004, offset 0. a(0) = 1 is the starting position itself.
my @A124004 = (
	1, 4, 12, 56, 244, 1396, 8200, 55092, 390216, 3005288, 24571056,
);

# HOW DEEP, AND WHY NOT DEEPER. Time, and only time. Depth 8 is about ten
# seconds here, depth 9 about a minute, and each ply after that is roughly eight
# times the last, so a full ladder is not something any test can hold.
#
# Depth 9 has been run and matches exactly, and it is the first depth at which a
# forfeited turn occurs at all, so it is the one that pins the convention. Set
# REVERSI_PERFT_DEPTH=9 to pay the minute and check it.
my $DEPTH = defined $ENV{REVERSI_PERFT_DEPTH} ? $ENV{REVERSI_PERFT_DEPTH} : 8;

my $passes_seen = 0;

sub perft {
	my ($board, $colour, $depth) = @_;
	return 1 if $depth == 0;

	my @moves = $B->legal_moves($board, $colour);
	if (!@moves) {
		my $them = $B->other($colour);
		# Neither side can move: the game is over, and a finished game is one
		# game however many plies were asked for.
		return 1 unless $B->has_move($board, $them);
		$passes_seen++;
		# A FORFEITED TURN COSTS A PLY OF ITS OWN. The sequence never says so
		# and this was determined by experiment against it; see the note at the
		# foot of this file. Getting it the other way round is off by 32 at
		# depth 9 and exact everywhere shallower, which is the worst shape a
		# disagreement can have.
		return perft($board, $them, $depth - 1);
	}

	my $count = 0;
	$count += perft($B->apply($board, $_, $colour), $B->other($colour), $depth - 1)
		for @moves;
	return $count;
}

my $start = Game::Reversi::Opening->board_for('othello');

subtest 'the ladder starts where the sequence starts' => sub {
	# a(1) = 4 is the check that the position is the right one: four legal
	# moves for Black from the Othello opening, which is the first thing the
	# sequence's documentation says about it.
	my @moves = sort map { $B->name_of($_) } $B->legal_moves($start, 'b');
	is_deeply(\@moves, [ qw(c4 d3 e6 f5) ],
		'Black has c4, d3, e6 and f5, which is A124004(1) = 4');
	done_testing();
};

for my $depth (0 .. $DEPTH) {
	last unless defined $A124004[$depth];
	$passes_seen = 0;
	my $got = perft($start, 'b', $depth);
	is($got, $A124004[$depth],
		"A124004($depth) = $A124004[$depth] games at the end of ply $depth");

	# Recorded rather than asserted, because it is the fact that decides how
	# far this file can go.
	diag("ply $depth reached $passes_seen forfeited turns") if $passes_seen;
}

done_testing();

__END__

=head1 THE PASS CONVENTION, AND HOW IT WAS SETTLED

A124004 counts "possible Reversi games at the end of the n-th ply" and B<never
says what a forfeited turn costs>. A turn with no legal move is skipped, and
whether that skip is itself a ply changes the count. Nothing in the sequence, its
documentation, or its references says which.

It was settled by experiment, and the shape of the disagreement is the reason it
is worth writing down:

=over 4

=item * B<To depth 8, both conventions agree and both are exact.> No forfeited
turn is reachable from the starting position before ply 8, which was measured
rather than assumed: this file counts the passes it hits and to depth 8 it hits
none.

=item * B<At depth 9 they differ.> With a forfeited turn costing nothing, the
count is 3,005,320 against the sequence's 3,005,288, which is 32 too many, from
24 forfeited turns first appearing at ply 8. With a forfeited turn costing a ply
of its own, the count is 3,005,288 exactly.

=back

So the sequence counts a pass as a ply, and this file does the same.

B<That is the dangerous shape for a disagreement to have>: exact agreement for
eight plies and then a small discrepancy at the ninth. The obvious reading is
that the engine has a deep bug, and the obvious response is to go looking for one
in code that is correct. It was neither: it was a convention nobody had written
down.

Note that this is a fact about B<counting games>, not about the rules or about
the search. L<Game::Reversi::Bot>'s alpha beta does not spend a ply on a
forfeited turn, which is a choice about search horizon and is unrelated.

=cut
