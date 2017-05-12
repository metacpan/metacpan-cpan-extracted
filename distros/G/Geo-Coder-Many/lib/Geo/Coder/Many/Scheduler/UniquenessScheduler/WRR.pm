package Geo::Coder::Many::Scheduler::UniquenessScheduler::WRR;

use strict;
use warnings;
use List::Util::WeightedRoundRobin;
use Carp;

use base 'Geo::Coder::Many::Scheduler::UniquenessScheduler';

our $VERSION = '0.01';

=head1 NAME

Geo::Coder::Many::Scheduler::UniquenessScheduler::WRR - Weighted Round Robin
scheduler (default)

=head1 DESCRIPTION

Returns items based on the weighted round-robin scheduling algorithm. It
inherits from UniquenessScheduler because it doesn't provide get_next_unique
and reset_available by itself.

=head1 METHODS

=head2 new

Constructs and returns a new WRR scheduler based on a weighted-list of items.
(Due to the way List::Util::WeightedRoundRobin is implemented, the items - in
this case the names of geocoders - are copied such that the list contains the
appropriate number of each item for its corresponding weight. Note that using
large, coprime weights may produce a large list...!)

=cut

sub new {
    my $class = shift;
    my $ra_geocoders = shift;
    
    my $WeightedList = List::Util::WeightedRoundRobin->new();
    my $self =  $class->SUPER::new({items => $ra_geocoders});
    $self->{weighted_list} 
        = $WeightedList->create_weighted_list( $ra_geocoders );

    unless( @{$self->{weighted_list}} ) {
        carp "Unable to create weighted list from list of geocoders";
    };

    bless $self, $class;
    return $self;
}

=head1 INTERNAL METHODS

=head2 _get_next

Returns the next most appropriate geocoder based on the weighted round robin
scoring.

=cut

## no critic (ProhibitUnusedPrivateSubroutines)
# ( _get_next is actually 'protected' )

sub _get_next {
    my $self = shift;
    my $next = shift @{$self->{weighted_list}};
    push @{$self->{weighted_list}}, $next;   
    return $next;
};

1;
