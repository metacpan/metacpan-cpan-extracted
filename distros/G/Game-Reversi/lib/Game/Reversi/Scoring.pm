package Game::Reversi::Scoring;

use strict;
use warnings;

use Game::Reversi::Board;

our $VERSION = '0.01';

sub count {
	my ($class, $board) = @_;
	return Game::Reversi::Board->count($board);
}

sub score {
	my ($class, $board) = @_;
	my $count = $class->count($board);
	my $empty = Game::Reversi::Board->empties($board);

	return { b => 32, w => 32 } if $count->{b} == $count->{w};

	my $winner = $count->{b} > $count->{w} ? 'b' : 'w';
	return {
		b => $count->{b} + ($winner eq 'b' ? $empty : 0),
		w => $count->{w} + ($winner eq 'w' ? $empty : 0),
	};
}

sub winner {
	my ($class, $board) = @_;
	my $count = $class->count($board);
	return undef if $count->{b} == $count->{w};
	return $count->{b} > $count->{w} ? 'b' : 'w';
}

1;

__END__

=head1 NAME

Game::Reversi::Scoring - what a finished game is worth

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    Game::Reversi::Scoring->count($board);    # { b => 20, w => 14 }
    Game::Reversi::Scoring->score($board);    # { b => 50, w => 14 }
    Game::Reversi::Scoring->winner($board);   # 'b'

=head1 DESCRIPTION

=head2 Two rules exist, and this implements the tournament one

WOF, World Othello Championships rules, section IV.7:

=over 4

The official score of the game will be determined by counting up the discs of
each colour on the board, B<counting empty squares for the winner>. In the event
of a draw, the score will always be 32-32.

=back

Wikipedia restates it and cites that document: "If the game ended before the
grid was completely filled, any empty squares are scored for the winner."

The other rule is simply the absence of that sentence. WOF's own public rules
page, and the casual rules sites, stop at "the player with the majority of their
colour showing is the winner". Under that reading a game ending 20-14 with thirty
squares empty is recorded 20-14; under the tournament rule it is 50-14.

B<Who wins is the same either way.> The empty squares go to the winner, so they
cannot change who that is. Only the recorded margin differs.

=head2 The tie is a branch, not arithmetic

"Counting empty squares for the winner" has no answer when there is no winner,
and WOF resolves it by fiat in the same sentence: a tie is recorded B<32-32>
whatever is on the board. A game ending 25-25 with fourteen squares empty is
officially 32-32.

Wikipedia notes the preferred word for such a result is B<tie>, and that "The
term 'draw' for such may also be heard, but is somewhat frowned upon". This
distribution nevertheless reports C<draw> from L<Game::Reversi::Result>, because
that is the word the site consuming it already uses for every other game and
inventing a third value for a terminology preference would break its ranking.

=head2 count and score are two names on purpose

C<count> is what is on the board and drives the live scoreboard. C<score> is the
official result and exists only at the end. A single function with a flag would
let a midgame evaluation reach for the end of game rule and conclude that every
position is worth 64.

=head1 METHODS

=head2 count

Discs on the board, by colour.

=head2 score

The official score. Always totals 64.

=head2 winner

Whoever has more discs, or C<undef> for a tie.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
