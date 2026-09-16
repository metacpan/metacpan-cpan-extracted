package Game::Gin::Hand;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Gin::Deadwood ();

our $VERSION = '0.01';

has cards => (is => 'rw', isa => ArrayRef);

sub count { return scalar @{ $_[0]->cards } }
sub full  { return $_[0]->count > 10 ? 1 : 0 }

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

sub best     { return Game::Gin::Deadwood::best($_[0]->cards) }
sub deadwood { return Game::Gin::Deadwood::deadwood($_[0]->cards) }

sub sorted { return [ sort { $a <=> $b } @{ $_[0]->cards } ] }

1;

__END__

=head1 NAME

Game::Gin::Hand - one player's cards

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $hand = Game::Gin::Hand->new(cards => [ @ids ]);

    $hand->count;        # 10, or 11 between a draw and a discard
    $hand->full;         # whether it is holding the extra card
    $hand->has_card($id);
    $hand->add($id);
    $hand->remove($id);
    $hand->deadwood;     # through Game::Gin::Deadwood
    $hand->best;

=head1 DESCRIPTION

A thin wrapper over a list of card ids. Ten cards between turns and eleven
between a draw and the discard that follows, which is the only time the size
changes.

Nothing in the engine depends on the order of a hand; C<sorted> is for display
and for a stable cache key.

=head1 METHODS

=head2 cards

The ids, as an arrayref.

=head2 count

How many.

=head2 full

Whether the hand is holding its eleventh card and therefore owes a discard.

=head2 has_card

Whether an id is in the hand.

=head2 add

Adds a card. Returns the hand.

=head2 remove

Removes one copy of a card. Returns the hand.

=head2 best

The best melding, from L<Game::Gin::Deadwood>.

=head2 deadwood

What the hand is left with.

=head2 sorted

The ids in id order.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
