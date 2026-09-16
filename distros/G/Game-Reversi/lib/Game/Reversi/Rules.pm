package Game::Reversi::Rules;

use strict;
use warnings;

use Game::Reversi::Board;
use Game::Reversi::Opening;

our $VERSION = '0.01';

sub next_turn {
	my ($class, $board, $just_moved) = @_;
	my $B = 'Game::Reversi::Board';

	return ($B->other($just_moved), undef) if $class->in_opening($board);

	my $them = $B->other($just_moved);
	return ($them, undef) if $B->has_move($board, $them);

	return ($just_moved, $them) if $B->has_move($board, $just_moved);

	return (undef, $them);
}

sub in_opening {
	my ($class, $board) = @_;
	return Game::Reversi::Opening->in_opening($board);
}

sub over {
	my ($class, $board) = @_;
	my $B = 'Game::Reversi::Board';
	return 0 if $class->in_opening($board);
	return ($B->has_move($board, 'b') || $B->has_move($board, 'w')) ? 0 : 1;
}

sub opening_turn {
	my ($class, $board, $first) = @_;
	my $B = 'Game::Reversi::Board';
	$first = Game::Reversi::Opening->first unless defined $first;
	return $first if $class->in_opening($board);
	return $first if $B->has_move($board, $first);
	my $them = $B->other($first);
	return $them if $B->has_move($board, $them);
	return undef;
}

sub legal {
	my ($class, $board, $colour) = @_;
	return Game::Reversi::Opening->legal($board, $colour)
		if $class->in_opening($board);

	require Game::Reversi::Move;
	my $B = 'Game::Reversi::Board';
	return map {
		Game::Reversi::Move->play($_, $colour, $B->flips_for($board, $_, $colour))
	} $B->legal_moves($board, $colour);
}

1;

__END__

=head1 NAME

Game::Reversi::Rules - whose turn, when a turn is forfeited, and when it ends

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my ($turn, $forfeited) = Game::Reversi::Rules->next_turn($board, 'b');
    my @moves = Game::Reversi::Rules->legal($board, $turn);

=head1 DESCRIPTION

Pure functions over a board. Nothing here holds state, prints, or knows what an
event is.

=head2 The pass is not a move a player makes

WOF rule 2:

=over 4

If on your turn you cannot outflank and flip at least one opposing disc, your
turn is forfeited and your opponent moves again. However, if a move is available
to you, you may not forfeit your turn.

=back

The first sentence makes the pass automatic, so the engine performs it and
L</legal> never returns a one element list holding a pass the player has no
choice about. The second makes a deliberate pass an error.

Together they have a consequence worth stating: because the engine forfeits for
anybody who cannot move, B<a seat on turn always has a move>. So a deliberate
pass can only ever be answered with C<has_move>. That is a property of the
design, not a coincidence.

=head2 The end is one condition, not two

WOF rule 8: "When it is no longer possible for either player to move, the game
is over", with the note that "It is possible for a game to end before all 64
squares are filled."

Wikipedia's rules section gives two conditions, a full board B<or> neither side
able to move, and its lead gives only the first, which is wrong as a standalone
rule. A full board is a strict special case of neither side being able to move,
so only the general condition is implemented. Writing both is how two conditions
drift apart, and the one that is a special case is the one that rots.

=head1 METHODS

=head2 next_turn

Given the board after a move and the colour that made it, returns
C<($turn, $forfeited)>. C<$turn> is C<undef> when the game is over.
C<$forfeited> is the colour whose turn was taken away, or C<undef>, so that a
caller can say so: a pass nobody mentions looks like the board changing twice on
its own.

=head2 in_opening

Whether discs are still being placed.

=head2 over

Whether the game is finished in this position, whoever is to move.

=head2 opening_turn

Who moves first in a position, given who has the first move by right. Handles a
position handed in from outside where that colour has nothing to do.

=head2 legal

The moves open to a colour, as L<Game::Reversi::Move> objects. Placements during
the opening, plays afterwards, never a pass.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
