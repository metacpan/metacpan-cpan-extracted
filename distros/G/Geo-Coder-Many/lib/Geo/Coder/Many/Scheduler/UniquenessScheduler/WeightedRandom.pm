package Geo::Coder::Many::Scheduler::UniquenessScheduler::WeightedRandom;

use strict;
use warnings;

use base 'Geo::Coder::Many::Scheduler::UniquenessScheduler';

our $VERSION = '0.01';

=head1 NAME

Geo::Coder::Many::Scheduler::WeightedRandom - Weighted random scheduler

=head1 DESCRIPTION

A scheduler which randomly picks an item from the list, with the probability of
each proportional to its weight.

=head1 METHODS

=head2 new

Construct and return a new scheduler for the array of pairs of geocoder names
and weights whose reference is passed in.

=cut

sub new {
    my $class = shift;
    my $ra_geocoders = shift;

    # Convert weights (= desired frequencies) into a cumulative distribution
    # function
    my $total_weight = 0;
    for my $rh_geo (@$ra_geocoders) {
        my $weight = $rh_geo->{weight};
        if ($weight <= 0) {
            warn "Warning - weight for "
                 .$rh_geo->{geocoder}
                 ." should be greater than zero"; 
        }
        $rh_geo->{weight} = $weight + $total_weight;
        $total_weight += $weight;
    }
    # (Normalization)
    for (@$ra_geocoders) {
        $_->{weight} /= $total_weight;
    }
    
    my $self =  $class->SUPER::new({items => $ra_geocoders});

    bless $self, $class;

    my @sorted = sort { $b->{weight} <=> $a->{weight} } @$ra_geocoders;
    $self->{ ra_geocoders } = \@sorted;

    return $self;
};

=head1 INTERNAL METHODS

=head2 _get_next

Overrides the method of the same name from the parent class, and is called by
get_next_unique instead.

=cut

## no critic (ProhibitUnusedPrivateSubroutines)
# ( _get_next is actually 'protected' )

sub _get_next {
    my $self = shift;
    my $r = rand;

    my $ra_geocoders = $self->{ra_geocoders};

    my $i = @$ra_geocoders - 1;
    while ($i > 0 and $r > $self->{ra_geocoders}->[$i]->{weight}) { --$i; }
    return $self->{ra_geocoders}->[$i]->{name};

};

1;

__END__
