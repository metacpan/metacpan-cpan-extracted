package Game::Senet::Move;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar;

our $VERSION = '0.02';

has side => (is => 'ro');

has roll => (is => 'ro');

has from => (is => 'ro');

has to => (is => 'ro');

has swap => (is => 'ro', default => 0);

has back => (is => 'ro', default => 0);

has off => (is => 'ro', default => 0);

has walk => (is => 'ro', default => 0);

sub trace {
    my ($self) = @_;
    return $self->from . ($self->back ? '<' : '>') . $self->to
        . ($self->swap ? 'x' : '');
}

1;

__END__

=head1 NAME

Game::Senet::Move - one piece, one roll: where it goes and what it meets

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my @moves = $board->moves(3, 'kendall');
    for my $move (@moves) {
        printf "%s from %d to %s%s\n", $move->side, $move->from, $move->to,
            $move->swap ? ', swapping' : '';
    }

=head1 DESCRIPTION

A move the rules allow, as the engine describes it. It is a value: it is made
by L<Game::Senet::Engine/moves> and read, and nothing changes it.

A move does not make itself. It says which piece goes where, and whether an
enemy piece stands there to be swapped.

=head1 METHODS

=head2 side

C<light> or C<dark>: whose piece moves.

=head2 roll

The roll, 1 to 5, the move was made for.

=head2 from

The house the piece stands on.

=head2 to

The house it goes to, or the word C<off> when it bears off.

=head2 swap

1 when an enemy piece stands on C<to>. It goes to C<from>: the two pieces
exchange houses.

=head2 back

1 for a backward move, which the rules allow only when no forward move exists.

=head2 off

1 when the piece bears off.

=head2 walk

1 when the piece landed by the walk down from house 15: the house it reached is
15, or the first empty house below it.

=head2 trace

A compact form for tests and for comparing one generator with another: the
house moved from, C<< > >> forward or C<< < >> backward, the house moved to, and
C<x> for a swap. C<< 22<20x >> is a backward move from 22 that swaps with the
enemy on 20.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
