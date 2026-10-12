package Game::Fanorona::Result;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.02';

my %WON   = map { $_ => 1 } qw(stones no_moves resign);
my %DRAWN = map { $_ => 1 } qw(repetition quiet ply_cap agreement);

has winner => (is => 'ro');

has how => (is => 'ro');

has position => (is => 'ro');

has moves => (is => 'ro', default => 0);

sub BUILD {
    my ($self) = @_;
    my ($how, $winner) = ($self->how, $self->winner);
    Carp::croak("Game::Fanorona::Result: '" . ($how // 'undef') . "' is not a way a game ends")
        unless defined $how && ($WON{$how} || $DRAWN{$how});
    if ($WON{$how}) {
        Carp::croak("Game::Fanorona::Result: a game ended by $how has a winner, white or black")
            unless defined $winner && ($winner eq 'white' || $winner eq 'black');
    }
    else {
        Carp::croak("Game::Fanorona::Result: a game ended by $how has no winner")
            if defined $winner;
    }
    return;
}

sub is_draw { $DRAWN{ $_[0]->how } ? 1 : 0 }

sub loser {
    my ($self) = @_;
    my $winner = $self->winner // return undef;
    return $winner eq 'white' ? 'black' : 'white';
}

sub ways { (sort(keys %WON), sort(keys %DRAWN)) }

1;

__END__

=head1 NAME

Game::Fanorona::Result - how a game of fanorona ended

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $result = $game->result or die 'the game is not over';
    if ($result->is_draw) { print 'drawn by ', $result->how, "\n" }
    else                  { print $result->winner, ' won by ', $result->how, "\n" }

=head1 DESCRIPTION

A value: who won, how, the position the game ended on and how many moves it
took.

=head2 The ways a game ends

Three with a winner:

=over 4

=item stones

A side has no stones left.

=item no_moves

A side to move had stones and no legal move, and has lost.

=item resign

A side gave up.

=back

and four without:

=over 4

=item repetition

The same position with the same side to move, for the third time.

=item quiet

Too many moves running that took nothing.

=item ply_cap

Too many moves altogether.

=item agreement

A draw was offered and accepted.

=back

L<Game::Fanorona::Rules/"How a game ends"> says which of these are
traditional and which are this distribution's.

=head1 CONSTRUCTORS

=head2 new

    my $result = Game::Fanorona::Result->new(
        how => 'stones', winner => 'white', position => $string, moves => 31,
    );

Croaks on a C<how> that is not one of the seven, on a win with no winner, and
on a draw with one.

=head1 METHODS

=head2 winner

C<white> or C<black>, or C<undef> for a draw.

=head2 loser

The other side, or C<undef> for a draw.

=head2 how

One of the seven words above.

=head2 is_draw

True when nobody won.

=head2 position

The position the game ended on.

=head2 moves

How many whole moves were made.

=head1 CLASS METHODS

=head2 ways

The seven words: the three wins, then the four draws.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
