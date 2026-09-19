package Game::Oware::Board;

use strict;
use warnings;

our $VERSION = '0.01';

use constant HOUSES    => 12;
use constant CELLS     => 14;
use constant SEEDS     => 48;
use constant PER_HOUSE => 4;
use constant P1_STORE  => 12;
use constant P2_STORE  => 13;

sub opening { return [ (PER_HOUSE) x HOUSES, 0, 0 ] }

sub clone { my ($class, $board) = @_; return [ @$board ] }

sub total {
	my ($class, $board) = @_;
	my $total = 0;
	$total += $_ for @$board;
	return $total;
}

sub other { my ($class, $seat) = @_; return $seat eq 'p1' ? 'p2' : 'p1' }

sub store_of {
	my ($class, $seat) = @_;
	die "Game::Oware::Board: there is no seat '$seat'"
		unless $seat eq 'p1' || $seat eq 'p2';
	return $seat eq 'p1' ? P1_STORE : P2_STORE;
}

sub owner_of {
	my ($class, $house) = @_;
	$class->assert_house($house);
	return $house < 6 ? 'p1' : 'p2';
}

sub houses_of {
	my ($class, $seat) = @_;
	die "Game::Oware::Board: there is no seat '$seat'"
		unless $seat eq 'p1' || $seat eq 'p2';
	return $seat eq 'p1' ? (0 .. 5) : (6 .. 11);
}

sub seeds_on_side {
	my ($class, $board, $seat) = @_;
	my $seeds = 0;
	$seeds += $board->[$_] for $class->houses_of($seat);
	return $seeds;
}

sub assert_house {
	my ($class, $house) = @_;
	die 'Game::Oware::Board: a house is 0 to 11'
		unless defined $house && $house =~ /\A\d+\z/ && $house < HOUSES;
	return $house;
}

sub sow {
	my ($class, $board, $house) = @_;
	$class->assert_house($house);

	my $hand = $board->[$house];
	die "Game::Oware::Board: house $house is empty, so there is nothing to sow"
		unless $hand;

	my $next = [ @$board ];
	$next->[$house] = 0;

	my $i = $house;
	my $last = $house;
	while ($hand) {
		$i = ($i + 1) % HOUSES;
		next if $i == $house;
		$next->[$i]++;
		$last = $i;
		$hand--;
	}

	return ($next, $last, $board->[$house]);
}

sub capture_chain {
	my ($class, $board, $last, $sown, $seat) = @_;
	$class->assert_house($last);

	my $foe = $class->other($seat);

	my @chain;
	my $i = $last;
	while (@chain < $sown) {
		last unless $class->owner_of($i) eq $foe;

		my $count = $board->[$i];
		last unless $count == 2 || $count == 3;

		push @chain, $i;
		$i = ($i - 1) % HOUSES;
	}

	return @chain;
}

1;

__END__

=head1 NAME

Game::Oware::Board - the twelve houses, the two stores, and the sowing

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Oware::Board;

    my $board = Game::Oware::Board->opening;
    my ($next, $last, $sown) = Game::Oware::Board->sow($board, 4);

=head1 DESCRIPTION

The position, and the one rule that moves seeds around it.

=head2 A board is an arrayref, not an object

Fourteen slots. Indices 0 to 5 are p1's houses, named C<A> to C<F>; indices 6
to 11 are p2's houses, named C<a> to C<f>; index 12 is p1's store and index 13
is p2's store.

The bot calls C<sow> millions of times and a board holds no invariant worth
protecting, so this is class methods over a plain array rather than a class
with accessors.

=head2 A cell holds a count, and zero is a real value

Every cell is defined from the first move to the last, which is the opposite of
L<Game::Reversi::Board>, where C<undef> means an empty square. Here an empty
house is a number rather than an absence, so C<< if ($board->[$house]) >> is a
legitimate "has seeds in it" test with nothing for it to be confused with.

=head2 Counter-clockwise is ascending index

The houses are laid out so that the ring arithmetic is trivial:

    f  e  d  c  b  a          11 10  9  8  7  6
    A  B  C  D  E  F           0  1  2  3  4  5

Left to right along p1's row and right to left along p2's, which in index terms
is simply increasing. C<F> is followed by C<a>, and C<f> is followed by C<A>.

=head2 The ring modulus is 12, never 14

Seeds are never sown into a store. The stores live in the same array as the
houses because the position is one thing and a result is computed from all
fourteen numbers, and the price of that representation is exactly this rule: a
sowing loop that takes the length of the array as its modulus banks a seed for
somebody every lap.

The bug is close to invisible. The counts stay plausible, the total is still
48, and the game plays on. It is also what every mancala implementation a
reader has met does, because in Kalah you B<do> sow into your own store. Oware
sows into neither.

=head2 The origin house is skipped, and not only on the twelfth seed

A house holding twelve or more seeds laps the board. The house the seeds came
from stays empty, so the step skips it every time it comes round, not once.
An implementation written around the literal twelve handles a house of twelve
and gets a house of twenty-five wrong.

=head2 The capture chain walks backwards

Sowing runs counter-clockwise, so the chain runs the other way: from the house
the final seed landed in, stepping B<down> the ring.

An implementation that continues forwards is inspecting houses the hand never
reached. It captures seeds the rule does not award, and it is wrong only where
both directions happen to hold twos and threes, which is to say wrong exactly in
the close games. On the position the Wikipedia article works through, forwards
takes five seeds where the article takes eight, and one of the two houses it
takes was never sown into at all.

=head2 The chain never outruns the hand

A hand of two seeds touched two houses, so a chain of three describes a capture
the sowing never reached. Without that cap, a long run of twos and threes left
over from earlier play is harvested by a move that went nowhere near it.

The cap is the loop's own condition rather than a check inside it, so it cannot
be stepped past. It binds only on short sows: a hand of twelve or more has
lapped the board and touched every house, and six is all the opponent has.

=head2 What stops the walk

The first house that is not the opponent's, or does not hold exactly two or
three. Two or more is not the rule and neither is at most three.

The ownership test is also what keeps the chain inside one row: walking back
from the opponent's first house arrives at your own last house, so the walk
terminates there without needing to know that a row boundary exists.
C<(0 - 1) % 12> is 11 in Perl, so the wrap needs no special case either.

=head2 An empty house dies rather than refusing

Sowing nothing is meaningless, so a caller that asks for it has a bug. A player
who picks an empty house is a refusal and is caught in the rules layer before
this is reached, which is the house rule that C<die> is for programmer error
and a flagged error object is for a move.

=head1 METHODS

=head2 opening

The starting position: four seeds in each of the twelve houses, both stores
empty.

=head2 clone

A shallow copy of a board, which is all a board ever needs.

=head2 total

The sum of all fourteen cells. It is 48 at every point in every game, which is
the cheapest real assertion in the distribution.

=head2 other

The other seat.

=head2 store_of

The index of a seat's store. Dies on an unknown seat.

=head2 owner_of

The seat that owns a house, 0 to 11.

=head2 houses_of

The six house indices a seat owns, in ascending order.

=head2 seeds_on_side

How many seeds are sitting in a seat's own six houses. Not a score: seeds in a
house belong to nobody until they are captured, and a player with forty seeds
in front of them is very often losing.

=head2 assert_house

Dies unless its argument is a house index. Used by everything that takes one.

=head2 sow

    my ($next, $last, $sown) = Game::Oware::Board->sow($board, $house);

Lifts every seed out of C<$house> and drops one in each house counter-clockwise
from it, skipping the origin and both stores. Returns a new board, the index the
final seed landed in, and how many seeds were sown.

The board passed in is not modified.

=head2 capture_chain

    my @chain = Game::Oware::Board->capture_chain($board, $last, $sown, $seat);

The houses C<$seat> captures, in walk-back order, or an empty list. C<$board> is
the board B<after> sowing, because every count in the rule is a post-sowing
count.

It finds the chain and does not apply it. Deciding whether a chain is a grand
slam needs the chain without its effects, so a function that captured as it
walked would have to be undone.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Notation>, L<Game::Oware::Move>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
