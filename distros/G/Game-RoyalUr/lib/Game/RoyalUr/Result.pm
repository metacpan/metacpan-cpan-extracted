package Game::RoyalUr::Result;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

my %HOW;
BEGIN {
    %HOW = (home => 1, resign => 1, ply_cap => 1);
}

has winner => (is => 'ro');

has how => (is => 'ro');

has final => (is => 'ro');

has home => (is => 'ro');

has plies => (is => 'ro', default => 0);

sub BUILD {
    my ($self) = @_;
    my ($winner, $how) = ($self->winner, $self->how);
    Carp::croak("Game::RoyalUr::Result: how is one of " . join(', ', sort keys %HOW))
        unless defined $how && $HOW{$how};
    Carp::croak("Game::RoyalUr::Result: a winner is 'light' or 'dark'")
        if defined $winner && $winner ne 'light' && $winner ne 'dark';
    Carp::croak('Game::RoyalUr::Result: a game that ran to the ply cap has no winner')
        if $how eq 'ply_cap' && defined $winner;
    Carp::croak("Game::RoyalUr::Result: a game ended by $how has a winner")
        if $how ne 'ply_cap' && !defined $winner;
    return;
}

sub is_draw { defined $_[0]->winner ? 0 : 1 }

sub loser {
    my ($self) = @_;
    my $winner = $self->winner;
    return undef unless defined $winner;
    return $winner eq 'light' ? 'dark' : 'light';
}

1;

__END__

=head1 NAME

Game::RoyalUr::Result - how a game of the Royal Game of Ur ended

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    if (my $result = $game->result) {
        print $result->is_draw ? "a draw\n" : $result->winner . " wins\n";
        print 'by ', $result->how, ' in ', $result->plies, " plies\n";
    }

=head1 DESCRIPTION

What a finished game came to. L<Game::RoyalUr/result> returns one of these
once a game is over, and C<undef> until then. It is read and never changed.

=head1 METHODS

=head2 winner

C<'light'> or C<'dark'>, or C<undef> for a draw.

=head2 loser

The other side, or C<undef> for a draw.

=head2 is_draw

True when nobody won.

=head2 how

=over 4

=item C<home>

The winner brought its last piece home.

=item C<resign>

The loser resigned.

=item C<ply_cap>

The game ran to the limit on its length and was drawn. A capture sends a
piece back to the start, so nothing else guarantees that a game ends; the
limit is set far above the length of any game play produces.

=back

=head2 final

The position the game ended in, as a string.

=head2 home

A hash reference, C<< { light => ..., dark => ... } >>: how many pieces each
side had brought home.

=head2 plies

How many moves and lost turns the game ran to.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
