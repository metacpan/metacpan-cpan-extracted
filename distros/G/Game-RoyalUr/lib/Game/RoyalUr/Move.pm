package Game::RoyalUr::Move;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar;

our $VERSION = '0.01';

has side => (is => 'ro');

has roll => (is => 'ro');

has from => (is => 'ro');

has to => (is => 'ro');

has from_step => (is => 'ro');

has to_step => (is => 'ro');

has from_cell => (is => 'ro');

has to_cell => (is => 'ro');

has captures => (is => 'ro', default => 0);

has rosette => (is => 'ro', default => 0);

has home => (is => 'ro', default => 0);

sub trace {
    my ($self) = @_;
    return $self->from_step . '>' . $self->to_step
        . ($self->captures ? 'x' : '')
        . ($self->rosette  ? '*' : '');
}

1;

__END__

=head1 NAME

Game::RoyalUr::Move - one piece moved by one roll

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my ($move) = $board->moves(3);

    print $move->from, ' to ', $move->to, "\n";      # hand to b1
    print "captures\n"   if $move->captures;
    print "roll again\n" if $move->rosette;

=head1 DESCRIPTION

What a roll lets one piece do: where it starts, where it lands, and what is
standing there. A move is made for you by L<Game::RoyalUr::Engine/moves>, and
describes a move without making it.

A move is read and never changed.

=head2 Two ways to say where

A place on the board has a B<name>, like C<d2>, which is the same for both
sides, and a B<step>, its number along the mover's own route, which is not.
A move carries both, because what stands on a square is a question about the
square and how far a piece has come is a question about the step.

=head1 METHODS

=head2 side

C<'light'> or C<'dark'>: whose piece it is.

=head2 roll

The roll that allows it, 1 to 4.

=head2 from

Where the piece starts: a square's name, or C<'hand'> for a piece entering the
board.

=head2 to

Where it lands: a square's name, or C<'home'> for a piece leaving the board at
the end of its route.

=head2 from_step

The step it starts on, counted along its side's route from 1. 0 is the hand.

=head2 to_step

The step it lands on. One more than the route's last step is home.

=head2 from_cell

The cell it starts on, as L<Game::RoyalUr::Engine> numbers cells, or -1 from
the hand.

=head2 to_cell

The cell it lands on, or -1 for home.

=head2 captures

True when an enemy piece stands where it lands.

=head2 rosette

True when it lands on a rosette. Never true of a piece going home.

=head2 home

True when the piece leaves the board.

=head2 trace

    2>5      a plain move from step 2 to step 5
    5>8x*    a capture on a rosette

The two steps with a C<E<gt>> between them, then C<x> for a capture and C<*>
for a rosette. A compact form for comparing lists of moves.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
