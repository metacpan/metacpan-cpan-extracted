package Game::Schnapsen::Hand;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Schnapsen::Card ();

our $VERSION = '0.01';

has cards => (is => 'rw', isa => ArrayRef);

sub count { return scalar @{ $_[0]->cards } }

sub has_card {
    my ($self, $card) = @_;
    return 0 unless defined $card;
    return scalar(grep { $_ == $card } @{ $self->cards }) ? 1 : 0;
}

sub add {
    my ($self, $card) = @_;
    $self->cards([ @{ $self->cards }, $card ]);
    return $self;
}

sub remove {
    my ($self, $card) = @_;
    my $seen = 0;
    $self->cards([ grep { $_ == $card && !$seen++ ? 0 : 1 } @{ $self->cards } ]);
    return $self;
}

sub points {
    my ($self) = @_;
    my $total = 0;
    $total += Game::Schnapsen::Card::points_of($_) for @{ $self->cards };
    return $total;
}

sub of_suit {
    my ($self, $suit) = @_;
    return [ grep { Game::Schnapsen::Card::suit_of($_) eq $suit } @{ $self->cards } ];
}

sub sorted { return [ sort { $a <=> $b } @{ $_[0]->cards } ] }

1;

__END__

=head1 NAME

Game::Schnapsen::Hand - one player's cards

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $hand = Game::Schnapsen::Hand->new(cards => [ @ids ]);

    $hand->count;          # 5 or 6 between tricks
    $hand->has_card($id);
    $hand->add($id);
    $hand->remove($id);
    $hand->of_suit('S');
    $hand->points;         # what the cards would be worth to whoever took them

=head1 DESCRIPTION

A thin wrapper over a list of card ids. Five cards in Schnapsen and six in
Sixty-Six between tricks, one fewer between playing to a trick and drawing from
the talon, which is the only time the size changes.

Nothing in the engine depends on the order of a hand; C<sorted> is for display
and for a stable cache key.

=head2 points is the holder's business and nobody else's

What a hand is worth matters to a bot deciding whether to close the talon, and
to nothing else. A consumer must not put it in an opponent's view: the card
points a player has B<taken> are public, because both players count openly, but
the points still in their hand are not.

=head1 METHODS

=head2 cards

The ids, as an arrayref.

=head2 count

How many.

=head2 has_card

Whether an id is in the hand.

=head2 add

Adds a card. Returns the hand.

=head2 remove

Removes one copy of a card. Returns the hand.

=head2 of_suit

The cards of one suit, as an arrayref, in the hand's own order.

=head2 points

The card points the hand is holding.

=head2 sorted

The ids in id order.

=head1 SEE ALSO

L<Game::Schnapsen::Card>, L<Game::Schnapsen::Deal>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
