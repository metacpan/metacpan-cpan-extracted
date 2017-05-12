package Geo::Coder::Many::Bing;

use strict;
use warnings;

use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::Bing - Plugin for the Bing geocoder

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

# Requires Geo::Coder::Bing 0.10 or above
sub _MIN_MODULE_VERSION { return '0.10'; }

=head1 SYNOPSIS

This class wraps Geo::Coder::Bing such that it can be used in
Geo::Coder::Many, by converting the results to a standard form.

Requires Geo::Coder::Bing >= 0.10

=head1 METHODS

=head2 geocode

Takes a location string, geocodes it using Geo::Coder::Bing, and returns the
result in a form understandable to Geo::Coder::Many

=cut

sub geocode {
    my $self = shift;
    my $location = shift;

    my @raw_replies = $self->{GeoCoder}->geocode( location => $location );

    my $http_response = $self->{GeoCoder}->response();

    my $Response = Geo::Coder::Many::Response->new( { location => $location } );

    my %convert = (
        'High'    => 0.9,
        'Medium'  => 0.5,
        'Low'     => 0.1,
        'Unknown' => undef,
    );

    foreach my $raw_reply (@raw_replies) {

        my $tmp = {
            address     => $raw_reply->{address}->{formattedAddress},
            country     => $raw_reply->{address}->{countryRegion},
            latitude    => $raw_reply->{point}->{coordinates}->[0],
            longitude   => $raw_reply->{point}->{coordinates}->[1],
            precision   => $convert{$raw_reply->{confidence}},
        };
        $Response->add_response( $tmp, $self->get_name());
    }

    $Response->set_response_code($http_response->code());
    return $Response;
}

=head2 get_name

The short name by which Geo::Coder::Many can refer to this geocoder.

=cut

sub get_name { my $self = shift; return 'bing ' . $self->{GeoCoder}->VERSION; }

1;

__END__

