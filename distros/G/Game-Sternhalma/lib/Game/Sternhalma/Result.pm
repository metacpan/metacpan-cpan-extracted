package Game::Sternhalma::Result;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

my %HOW = map { $_ => 1 } qw(home cap deadlock resign);

has how => (is => 'ro');

has places => (is => 'ro');

has ply => (is => 'ro', default => 0);

has position => (is => 'ro');

sub BUILD {
    my ($self) = @_;
    my $how = $self->how;
    Carp::croak("Game::Sternhalma::Result: '" . (defined $how ? $how : 'undef') . "' is not a way a game ends")
        unless defined $how && $HOW{$how};
    my $places = $self->places;
    Carp::croak('Game::Sternhalma::Result: places is a place for every seat, 1 the best')
        unless ref $places eq 'ARRAY' && @$places && !grep { !defined || !/\A[1-9][0-9]*\z/ } @$places;
    return;
}

sub seats { scalar @{ $_[0]->places } }

sub place_of {
    my ($self, $seat) = @_;
    return undef unless defined $seat && $seat =~ /\A[0-9]+\z/ && $seat < $self->seats;
    return $self->places->[$seat];
}

# The seats in the order they finished, best first; seats sharing a place in
# seat order.
sub ranking {
    my ($self) = @_;
    my $p = $self->places;
    return sort { $p->[$a] <=> $p->[$b] || $a <=> $b } 0 .. $#$p;
}

# The one seat in first place, or undef when first is shared.
sub winner {
    my ($self) = @_;
    my @first = grep { $self->places->[$_] == 1 } 0 .. $self->seats - 1;
    return @first == 1 ? $first[0] : undef;
}

sub ways { sort keys %HOW }

1;

__END__

=head1 NAME

Game::Sternhalma::Result - how a game of sternhalma ended, and in what places

=head1 SYNOPSIS

    my $result = $game->result;               # once $game->over
    print $result->how, "\n";                  # home, cap, deadlock or resign
    print join(' ', $result->ranking), "\n";   # seats, best first
    print $result->winner // 'shared', "\n";

=head1 DESCRIPTION

A game of more than two ends with every seat placed: the seats home in the
order they got there, then the seats still racing, then the seats that
resigned. At the cap, or when nobody could move, seats still racing are
placed by how far they are from home, and equal distances share a place.

=head1 METHODS

=head2 how

C<home> (everyone but one home), C<cap> (the move limit), C<deadlock> (nobody
could move) or C<resign> (resigning left one seat racing).

=head2 places

An array reference of every seat's place, in seat order, 1 the best.

=head2 place_of

    $result->place_of($seat)

=head2 ranking

The seats best first; seats that share a place in seat order.

=head2 winner

The seat in first place, or C<undef> when first place is shared.

=head2 seats

How many seats played.

=head2 ply

Moves and passes made.

=head2 position

The final position as a string.

=head2 ways

Every way a game can end.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
