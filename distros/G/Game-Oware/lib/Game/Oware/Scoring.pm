package Game::Oware::Scoring;

use strict;
use warnings;

use Game::Oware::Board;

our $VERSION = '0.01';

use constant TO_WIN  => 25;
use constant DRAW_AT => 24;

sub captured {
	my ($class, $board) = @_;
	return {
		p1 => $board->[ Game::Oware::Board->P1_STORE ],
		p2 => $board->[ Game::Oware::Board->P2_STORE ],
	};
}

sub taken {
	my ($class, $board, $chain) = @_;
	my $seeds = 0;
	$seeds += $board->[$_] for @$chain;
	return $seeds;
}

sub leader {
	my ($class, $board) = @_;
	my $captured = $class->captured($board);
	return undef if $captured->{p1} == $captured->{p2};
	return $captured->{p1} > $captured->{p2} ? 'p1' : 'p2';
}

sub target_reached {
	my ($class, $board) = @_;
	my $captured = $class->captured($board);
	return 'p1' if $captured->{p1} >= TO_WIN;
	return 'p2' if $captured->{p2} >= TO_WIN;
	return undef;
}

sub is_draw {
	my ($class, $board) = @_;
	my $captured = $class->captured($board);
	return $captured->{p1} == DRAW_AT && $captured->{p2} == DRAW_AT ? 1 : 0;
}

sub score {
	my ($class, $board, $status) = @_;
	return undef unless defined $status && $status eq 'finished';
	return $class->captured($board);
}

sub sweep_to {
	my ($class, $board, $seat) = @_;
	my $next = [ @$board ];
	my $store = Game::Oware::Board->store_of($seat);

	for my $house (0 .. Game::Oware::Board->HOUSES - 1) {
		$next->[$store] += $next->[$house];
		$next->[$house] = 0;
	}

	return $next;
}

sub sweep_split {
	my ($class, $board) = @_;
	my $next = [ @$board ];

	for my $seat (qw/ p1 p2 /) {
		my $store = Game::Oware::Board->store_of($seat);
		for my $house (Game::Oware::Board->houses_of($seat)) {
			$next->[$store] += $next->[$house];
			$next->[$house] = 0;
		}
	}

	return $next;
}

1;

__END__

=head1 NAME

Game::Oware::Scoring - what has been captured, and what the result was

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Oware::Scoring;

    Game::Oware::Scoring->captured($board);            # { p1 => 8, p2 => 3 }
    Game::Oware::Scoring->score($board, 'active');     # undef
    Game::Oware::Scoring->target_reached($board);      # 'p1', or undef

=head1 DESCRIPTION

=head2 captured and score are two names on purpose, and not for the reason you
would expect

In L<Game::Reversi::Scoring> the two names exist because the arithmetic
differs: a disc count is not the official score, which awards the empty squares
to the winner, and an engine that reported one for the other would disagree with
every published record.

B<In Oware the arithmetic is identical.> A seat's score is the seeds in its
store, during the game and at the end of it, and nothing is redistributed when
the game stops. The plan for this distribution claimed the two would diverge at
the end and that claim is wrong: the sweeps move seeds into the stores before
the game is over, not after, so a store is a store throughout.

What differs is B<when the number is valid>, which is why there are still two
names. C<captured> is a running total and is always available. C<score> is a
result, needs to be told the game has finished, and is C<undef> otherwise. A
caller that reaches for C<score> in the middle of a game gets nothing rather
than a plausible number it can publish by accident, and that is the whole of the
protection this pair buys.

=head2 There are two sweeps, and they are two functions on purpose

Two sentences in the source, three paragraphs apart, describe the same physical
gesture with two different owners:

    the failed feed: "the current player captures all seeds in their own
                      territory"

    the cycle:       "each player captures the seeds on their side of the
                      board"

The first is B<one-sided>, to the seat that could not feed, and it takes every
seed on the board. The second is a B<split>: each row goes to its own store.

One C<sweep($board, $seat_or_undef)> is how the failed-feed ending quietly
starts splitting, or the cycle ending quietly starts handing everything to
whoever moved last. B<Neither shows up as an error.> Both produce a finished
game with a plausible score, both leave the total at forty-eight, and both look
right in a log. The only test that catches the confusion is one that sweeps the
same board both ways and asserts the two results differ, which is why
C<t/14-endings.t> has one.

=head2 Seeds on the board belong to nobody

A player with forty seeds sitting in their row has captured nothing and is very
often losing, so there is no function here that counts them. That is
L<Game::Oware::Board/seeds_on_side>, which says the same thing in its own POD,
and it is a position feature rather than a score.

=head2 Twenty-five wins and twenty-four all draws

"The game is over when one player has captured 25 or more seeds, or each player
has taken 24 seeds (draw)." Twenty-five B<or more>: a single capture can carry a
store from twenty-three to twenty-six.

=head1 FUNCTIONS

=head2 TO_WIN

Twenty-five, the seeds that win a game.

=head2 DRAW_AT

Twenty-four, the seeds each that draw one.

=head2 captured

The running totals as C<< { p1 => N, p2 => N } >>.

=head2 taken

How many seeds a capture chain holds, without applying it. Takes the board the
chain was found on.

=head2 leader

Who has captured more, or C<undef> if they are level. Not a prediction.

=head2 target_reached

The seat with twenty-five or more, or C<undef>.

=head2 is_draw

True when both stores hold exactly twenty-four.

=head2 score

    Game::Oware::Scoring->score($board, $status);

The official result, or C<undef> unless C<$status> is C<finished>.

=head2 sweep_to

Every seed on the board into one seat's store. The failed-feed ending. Returns
a new board.

=head2 sweep_split

Each seat's own row into its own store. The cycle ending. Returns a new board.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Board>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
