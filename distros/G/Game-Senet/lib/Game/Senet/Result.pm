package Game::Senet::Result;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.02';

my %HOW;
BEGIN {
    %HOW = (home => 1, resign => 1, ply_cap => 1);
}

has winner => (is => 'ro');

has how => (is => 'ro');

has final => (is => 'ro');

has home => (is => 'ro');

has plies => (is => 'ro', default => 0);

has throws => (is => 'ro', default => 0);

sub BUILD {
    my ($self) = @_;
    my ($winner, $how) = ($self->winner, $self->how);
    Carp::croak('Game::Senet::Result: how is one of ' . join(', ', sort keys %HOW))
        unless defined $how && $HOW{$how};
    Carp::croak("Game::Senet::Result: a winner is 'light' or 'dark'")
        if defined $winner && $winner ne 'light' && $winner ne 'dark';
    Carp::croak('Game::Senet::Result: a game that ran to the ply cap has no winner')
        if $how eq 'ply_cap' && defined $winner;
    Carp::croak("Game::Senet::Result: a game ended by $how has a winner")
        if $how ne 'ply_cap' && !defined $winner;
    return;
}

sub is_draw { $_[0]->how eq 'ply_cap' ? 1 : 0 }

sub loser {
    my ($self) = @_;
    my $winner = $self->winner;
    return undef unless defined $winner;
    return $winner eq 'light' ? 'dark' : 'light';
}

1;

__END__

=head1 NAME

Game::Senet::Result - how a game of Senet ended

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    if (my $result = $game->result) {
        print $result->is_draw ? "drawn\n" : $result->winner . " won by " . $result->how . "\n";
    }

=head1 DESCRIPTION

The end of a game: who won and how, the last position, both homes, and how
long it took. There is no draw but the ply cap: a game that reaches it has no
winner, whoever is ahead.

=head1 METHODS

=head2 winner

C<light>, C<dark>, or C<undef> for a draw.

=head2 loser

The other side, or C<undef>.

=head2 how

C<home> when a side bore off every piece, C<resign>, or C<ply_cap>.

=head2 is_draw

True for C<ply_cap> and nothing else.

=head2 final

The last position, as a position string.

=head2 home

C<< { light => $n, dark => $n } >>: the pieces each side bore off.

=head2 plies

Moves and forfeits made.

=head2 throws

Throws of the sticks made.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
