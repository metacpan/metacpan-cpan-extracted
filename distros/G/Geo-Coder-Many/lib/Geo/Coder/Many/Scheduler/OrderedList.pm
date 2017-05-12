package Geo::Coder::Many::Scheduler::OrderedList;

use strict;
use warnings;

use base 'Geo::Coder::Many::Scheduler';

our $VERSION = '0.01';

=head1 NAME

Geo::Coder::Many::Scheduler::OrderedList - Ordered list scheduler

=head1 DESCRIPTION

This is a scheduler representing a strict preferential order - it will always
use the first geocoder in the list, unless it fails, in which case it'll fall
back to the second in the list, and then the third, and so on.

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $ra_items = shift;

    my @names =
        map { $_->{name} } 
        sort { $b->{weight} <=> $a->{weight}; } @$ra_items;

    my $self = { items => \@names };
    bless $self, $class;

    $self->reset_available();

    return $self;
}

=head2 reset_available

Resets the list back to how it was initially set.

=cut

sub reset_available {
    my $self = shift;
    @{$self->{ available_items }} = @{$self->{items}};
    return;
}

=head2 get_next_unique

Returns the next item in the list.

=cut

sub get_next_unique {
    my $self = shift;
    return shift @{$self->{ available_items }};
}

=head2 next_available 

Returns zero if there are items available, and
-1 if there aren't.

=cut

sub next_available {
    my $self = shift;

    if ( 0 < @{$self->{ available_items }} ) {
        return 0;
    }
    return 1;
}

1;

__END__
