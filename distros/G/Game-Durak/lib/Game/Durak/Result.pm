package Game::Durak::Result;

use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(out_seats places_for result_for resign_for);

sub out_seats {
    my ($counts, $talon_left) = @_;
    return () if $talon_left;
    return grep { !$counts->{$_} } sort { $a <=> $b } keys %$counts;
}

sub places_for {
    my ($fool, $seats) = @_;
    return { map { $_ => (defined $fool && $_ == $fool) ? 2 : 1 } @$seats };
}

sub result_for {
    my ($counts, $talon_left) = @_;

    my @seats = sort { $a <=> $b } keys %$counts;
    my @out   = out_seats($counts, $talon_left);
    return undef unless @out;

    my @holding = grep { $counts->{$_} } @seats;

    return {
        outcome => 'draw',
        fool    => undef,
        places  => places_for(undef, \@seats),
    } unless @holding;

    return {
        outcome => 'fool',
        fool    => $holding[0],
        places  => places_for($holding[0], \@seats),
    };
}

sub resign_for {
    my ($seat, $seats) = @_;
    return {
        outcome => 'resign',
        fool    => $seat,
        places  => places_for($seat, $seats),
    };
}

1;

__END__

=head1 NAME

Game::Durak::Result - who the fool is, and when nobody is

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Durak::Result qw(out_seats result_for);

    out_seats({ 1 => 0, 2 => 4 }, 0);        # (1)
    result_for({ 1 => 0, 2 => 4 }, 0);       # fool => 2
    result_for({ 1 => 0, 2 => 0 }, 0);       # draw
    result_for({ 1 => 0, 2 => 4 }, 3);       # undef, the talon still has cards

=head1 DESCRIPTION

Arithmetic over two card counts and the size of the talon. No game object, no
hands, no history: what is left of a deal at the moment a bout closes is two
numbers and the talon, and everything this module answers follows from them.

=head2 A seat is out only when the talon is empty

    As players run out of cards they drop out of the play ... the game
    continues after the talon is exhausted until at the end of a bout, only
    one player has any cards left. This player is the loser (the fool).
        -- https://www.pagat.com/beating/podkidnoy_durak.html

While the talon holds anything, every hand is refilled to six, so a seat that
has just played its last card is not out: it draws. That is why C<out_seats>
takes the talon and answers nothing while it has cards in it, rather than the
caller remembering to ask.

The caller asks B<after> the refill and B<at a bout end>, which is the source's
own rule: "the game can only end at the end of an bout".

=head2 The game has no winner, only a loser

    This game has no winner - only a loser, or a losing team if played with
    partnerships.

At two seats a loser implies a winner, so C<places> can say what the rating
of a two seat game needs: the durak is second and the other seat is first.
That is the whole reason this engine plays two seats and not four, where the
rules decline to rank the other three.

=head2 A deal can be drawn

    If after the final attack has been beaten off, no one has any cards left,
    the game is a draw.

It needs the last bout to empty both hands at once: the attacker plays out and
the defender answers with exactly the cards it has left. It is rare, it is on
the page, and a shared first place is what it comes to here.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 out_seats

    out_seats($counts, $talon_left);

The seats with no cards, in seat order, and nothing at all while the talon
has cards in it.

=head2 result_for

    result_for($counts, $talon_left);

Undef while the deal has further to run, otherwise a hashref of C<outcome>
(C<fool> or C<draw>), C<fool> (the seat, or undef) and C<places>.

=head2 resign_for

    resign_for($seat, [ 1, 2 ]);

The same shape for a seat that gives up: it is the fool, whatever it was
holding.

=head2 places_for

    places_for($fool, [ 1, 2 ]);

A hashref of seat to place, the fool second and everybody else first, and
everybody first when there is no fool. A hashref and not an arrayref: a
consumer that takes a list of places in seat order and one that takes a map
are one silent bug apart.

=head1 SEE ALSO

L<Game::Durak>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
