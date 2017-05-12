#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::Deck;
# ABSTRACT: pandemic card deck
$Games::Risk::Deck::VERSION = '4.000';
use Moose 0.92;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::Risk::Logger qw{ debug };


# -- builders / finishers

sub DEMOLISH { debug( "~deck: $_[0]\n" ); }


# -- accessors


has cards => (
    ro, auto_deref,
    default    => sub { [] },
    traits     => ['Array'],
    isa        => 'ArrayRef[Games::Risk::Card]',
    handles => {
#        clear   => 'clear',
#        count   => 'count',
        all     => 'elements',
        get     => 'shift',
        return  => 'push',
        add     => 'push',
        _firstidx => 'first_index',
        _delete   => 'delete',
    },
);


# -- public methods


sub del {
    my ($self, $card) = @_;
    my $idx = $self->_firstidx( sub { $_[0] eq $card } );
    $self->_delete( $idx );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Games::Risk::Deck - pandemic card deck

=head1 VERSION

version 4.000

=head1 DESCRIPTION

A L<Games::Risk::Deck> contains a set of L<Games::Risk::Card>, with
methods to handle this set.

=head1 ATTRIBUTES

=head2 cards

The set of L<Games::Risk::Card>s hold in the deck.

=head1 METHODS

=head2 all

    my @cards = $deck->cards;
    my @cards = $deck->all;

Return all the cards in the C<$deck>.

=head2 get

    my $card = $deck->get;

Get the next C<$card> in the deck.

=head2 add

=head2 return

    $deck->add( $card );
    $deck->return( $card );

Return C<$card> to the deck of cards.

=head2 del

    $deck->del( $card );

Remove a C<$card> from the deck.

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
