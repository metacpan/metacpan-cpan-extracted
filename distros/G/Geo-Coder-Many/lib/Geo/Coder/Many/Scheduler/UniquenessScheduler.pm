package Geo::Coder::Many::Scheduler::UniquenessScheduler;

use strict;
use warnings;

use List::MoreUtils qw( first_index );

use base 'Geo::Coder::Many::Scheduler';

our $VERSION = '0.01';

=head1 NAME

Geo::Coder::Many::Scheduler::UniquenessScheduler - Scheduler base class which
ensures uniqueness

=head1 DESCRIPTION

A base class for enforcing correct behaviour of get_next_unique (and the other
methods) even when a scheduling scheme might not take this into account. Note:
this may alter the properties of the scheduling scheme!

Subclasses should 

=head1 METHODS

=head2 new

Creates a UniquenessScheduler object and returns it. This should not be called
directly, but by any subclasses, via SUPER.

=cut

sub new {
    my $class = shift;
    my $args = shift;

    # (Map from geocoder+weight hash, for the time being)
    my @items_copy = map { $_->{name} } @{$args->{items}};

    my $self = { items => \@items_copy};
    bless $self, $class;

    # Initialize available_items
    $self->reset_available();
    return $self;
};

=head2 reset_available

Update the set of currently available items to the full set of items initially
provided.

=cut

sub reset_available {
    my $self = shift;
    @{$self->{available_items}} = @{$self->{items}};
    return;
};

=head2 get_next_unique

Uses _get_next (which has been overridden) to obtain the next scheduled item, 

=cut

sub get_next_unique {
    my $self = shift;

    my ($item, $item_pos);
    while ( 0 < @{$self->{available_items}} ) {

        # Get the next element (possibly one we've seen before)
        $item = $self->_get_next(); 

        # Return undef if _get_next has no more items
        return if !defined $item;

        # Check whether we've seen this item before
        $item_pos = first_index { $_ eq $item } @{$self->{available_items}};

        # Finish if we haven't seen it
        last if ($item_pos > -1);
    }

    # If we ran out of items, return undef.
    if ( !@{$self->{available_items}} ) {
        return;
    }
    
    # Remember that we've seen this item, by removing it from the list of those
    # available
    if ( $item_pos > -1 ) {
        splice @{$self->{available_items}},$item_pos,1;
    }
    return $item;
}

=head2 next_available

Zero if there are items remaining; undef if there aren't.

=cut

sub next_available {
    my $self = shift;
    if ( 0 == @{$self->{available_items}} ) {
        return;
    }
    else {
        return 0;
    }
}

=head2 _get_next

Shoudl be implemented by a subclass

=cut

sub _get_next {
    die "This method must be over-ridden.\n";
}
    
=head2 process_feedback

Does nothing by default; may be overridden

=cut

sub process_feedback {
    return;
}

1;

