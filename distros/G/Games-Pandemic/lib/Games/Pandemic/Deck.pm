#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::Deck;
{
  $Games::Pandemic::Deck::VERSION = '1.120510';
}
# ABSTRACT: pandemic card deck

use Moose 0.92;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- builders / finishers

sub DEMOLISH {
    my $self = shift;
    debug( "~deck: $self\n" );
}


# -- accessors

has cards => (
    required,
    auto_deref,
    traits     => ['Array'],
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    handles => {
        clear_cards => 'clear',
        nbcards     => 'count',
        future      => 'elements',
        next        => 'pop',
        refill      => 'push',
        last        => 'shift',
    },
);

has _pile => (
    auto_deref,
    traits => ['Array'],
    isa        => 'ArrayRef[Games::Pandemic::Card]',
    default    => sub { [] },
    handles => {
        _clear_pile => 'clear',
        nbdiscards  => 'count',
        past        => 'elements',
        discard     => 'push',
    },
);

has previous_nbdiscards => ( rw, isa=>'Int' );


# -- public methods


sub clear_pile {
    my $self = shift;
    $self->set_previous_nbdiscards( $self->nbdiscards );
    $self->_clear_pile;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Deck - pandemic card deck

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

A C<Games::Pandemic::Deck> contains 2 sets of C<Games::Pandemic::Card>:
a drawing deck and a discard pile.

=head1 METHODS

=head2 $deck->clear_pile;

Store the number of cards in the pile in C<previous_nbdiscards> and
clear the pile.

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

