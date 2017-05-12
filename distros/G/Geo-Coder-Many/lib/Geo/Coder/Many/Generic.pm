package Geo::Coder::Many::Generic;

use strict;
use warnings;
use Carp;

use Geo::Coder::Many::Response;

our $VERSION = '0.01';

=head1 NAME

Geo::Coder::Many::Generic - Base plugin class

=head1 DESCRIPTION

Base class for Geo::Coder::Many::* (Geo::Coder wrapper) classes

=head1 METHODS

=head2 new

Construct and return a new instance of the class.
Arguments should be provided in a hash with keys 'geocoder' and 'daily_limit'.

=cut

sub new {
    my $class = shift;
    my $args = shift;

    my $self = {
        GeoCoder    => $args->{geocoder},
        daily_limit => $args->{daily_limit},
    };

    bless $self, $class;
    return $self;
}

=head2 geocode

The main geocode method, to be overridden by subclasses. Should take a location
string, geocode it using the wrapped class, and return the results (converted
to a standard format)

=cut

sub geocode {
    croak "This method must be over-ridden";
}

=head2 get_daily_limit

Getter for daily_limit.

=cut

sub get_daily_limit {
    return shift->{daily_limit};
}

=head2 get_name

Return the short name of the geocoder being wrapped (should be overriden by the
subclass)

=cut

sub get_name {
    croak "This method must be over-ridden";
};

1;

__END__

