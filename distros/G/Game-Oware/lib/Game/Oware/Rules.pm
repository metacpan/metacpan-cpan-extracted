package Game::Oware::Rules;

use strict;
use warnings;

use Game::Oware::Board;
use Game::Oware::Move;
use Game::Oware::Scoring;
use Game::Oware::Variant ();

our $VERSION = '0.01';

sub starved {
	my ($class, $board, $seat) = @_;
	return Game::Oware::Board->seeds_on_side($board, $seat) ? 0 : 1;
}

sub reaches {
	my ($class, $house, $seat) = @_;
	Game::Oware::Board->assert_house($house);
	my $position = $seat eq 'p1' ? $house : $house - 6;
	return 6 - $position;
}

sub feeds {
	my ($class, $board, $house, $seat, $variant) = @_;
	return 0 unless $board->[$house];

	my ($next) = $class->resolve($board, $house, $seat, $variant);
	return Game::Oware::Board->seeds_on_side($next, Game::Oware::Board->other($seat))
		? 1 : 0;
}

sub sowable {
	my ($class, $board, $seat) = @_;
	return grep { $board->[$_] } Game::Oware::Board->houses_of($seat);
}

sub legal_moves {
	my ($class, $board, $seat, $variant) = @_;
	Game::Oware::Variant::check_variant($variant);

	my @sowable = $class->sowable($board, $seat);
	return () unless @sowable;

	if (Game::Oware::Variant::grand_slam($variant) eq 'illegal_unless_only') {
		my @kind = grep { $class->feeds($board, $_, $seat, $variant) } @sowable;
		return @kind ? @kind : @sowable;
	}

	return @sowable
		unless $class->starved($board, Game::Oware::Board->other($seat));

	return grep { $class->feeds($board, $_, $seat, $variant) } @sowable;
}

sub resolve {
	my ($class, $board, $house, $seat, $variant) = @_;
	Game::Oware::Variant::check_variant($variant);

	my $foe = Game::Oware::Board->other($seat);
	my ($next, $last, $sown) = Game::Oware::Board->sow($board, $house);

	my @chain = Game::Oware::Board->capture_chain($next, $last, $sown, $seat);
	my $taken = Game::Oware::Scoring->taken($next, \@chain);

	my $slam = @chain
		&& Game::Oware::Board->seeds_on_side($next, $foe) == $taken ? 1 : 0;

	my $policy = Game::Oware::Variant::grand_slam($variant);

	my (@captured, @forfeited);
	if ($slam && $policy eq 'no_capture') {
		@forfeited = @chain;
		$taken = 0;
	}
	else {
		@captured = @chain;
		$next->[$_] = 0 for @captured;
		$next->[ Game::Oware::Board->store_of($seat) ] += $taken;
	}

	my $move = Game::Oware::Move->new(
		seat      => $seat,
		house     => $house,
		sown      => $sown,
		last      => $last,
		captured  => \@captured,
		taken     => $taken,
		slammed   => $slam,
		forfeited => \@forfeited,
	);

	return ($next, $move);
}

1;

__END__

=head1 NAME

Game::Oware::Rules - what a move is allowed to do, and what it does

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Oware::Rules;

    my @legal = Game::Oware::Rules->legal_moves($board, 'p1', 'abapa');
    my ($next, $move) = Game::Oware::Rules->resolve($board, 4, 'p1', 'abapa');

=head1 DESCRIPTION

=head2 The legal move list is not "the houses with seeds in them"

The feeding obligation prunes it, and that is the whole of this module's reason
to exist. A bot built on the unpruned list offers moves the rules then refuse,
which surfaces as a fault in whatever is consuming the engine rather than in the
bot, because a terminal only ever offers what C<legal_moves> returned and an
adapter is the only thing that ever sees the two disagree.

=head2 A grand slam is decided on the resulting board, not on the chain's length

A chain of six houses is not automatically a grand slam: the opponent may hold
seeds in a house the chain stopped short of. A chain of one house is a grand
slam if that house held their last seeds.

So the question is "would applying this leave them with nothing", asked of the
board, and it is asked before the chain is applied. That is why
L<Game::Oware::Board/capture_chain> finds a chain without taking it.

=head2 Under no_capture, feeding is the same question as reaching

"If an opponent's houses are all empty, the current player must make a move that
gives the opponent seeds." That reads as though it needs a simulation - sow,
capture, then see whether anything survived - and under the shipped policy it
does not. The derivation, because a reader will otherwise assume the code is
cutting a corner:

=over

=item *

the premise is that the opponent holds B<zero> seeds;

=item *

so the only seeds that can be on their side after the move are the ones this
sowing just put there;

=item *

so a chain that captures all of them is capturing all of the opponent's seeds,
which is a grand slam by definition;

=item *

so under C<no_capture> that capture is forfeited and the seeds stay;

=item *

therefore B<any move that reaches the opponent's row feeds them>, and no move
that fails to reach it can.

=back

Which reduces the test to arithmetic: a house needs at least C<6 - position>
seeds, where C<position> is 0 to 5 within its own row. C<reaches> returns that
number.

B<The code simulates anyway, and the suite asserts the two agree.> Two
independent derivations of one predicate is cheap and real, and the arithmetic
is the half that silently stops being true if the policy is ever changed: under
C<illegal_unless_only> the argument above does not apply at all, because a slam is
allowed and what it leaves behind depends on the capture. That is one more mark
against the variations this distribution did not take, and it is worth more than
the line of code it saves.

=head2 A seat on turn always has seeds, so there is no pass

Under C<no_capture> a seat can never be reduced to nothing: a capture that would
do it is a grand slam and is forfeited. So a player is always able to move, and
the empty list C<legal_moves> can return means one thing only - the opponent is
starved and nothing this seat can play reaches them. That is the failed-feed
ending, not a turn forfeit, and any code that treats it as a pass has broken the
claim L<Game::Oware::Notation> makes about transcripts.

=head1 METHODS

=head2 starved

True when a seat has no seeds in any of its six houses.

=head2 reaches

How many seeds a house needs in order to reach the opponent's row.

=head2 feeds

Whether sowing a house leaves the opponent with seeds on their side. By
simulation.

=head2 sowable

A seat's houses that hold at least one seed, before the feeding filter.

=head2 legal_moves

The houses a seat may sow from, in ascending order. Empty only through the
failed-feed ending.

=head2 resolve

    my ($next, $move) = Game::Oware::Rules->resolve($board, $house, $seat, $variant);

Sows, finds the chain, decides the grand slam, and applies whichever of the two
outcomes the variant calls for. Returns the new board and a
L<Game::Oware::Move>. The board passed in is not modified.

It does not know whose turn it is, whether the game is over, or what the move
log says. Those are L<Game::Oware>'s.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Board>, L<Game::Oware::Variant>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
