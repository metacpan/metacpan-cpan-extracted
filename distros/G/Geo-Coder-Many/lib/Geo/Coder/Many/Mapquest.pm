package Geo::Coder::Many::Mapquest;

use warnings;
use strict;
use Carp;
use Geo::Coder::Many::Generic;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::Mapquest - Mapquest plugin Geo::Coder::Many

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

# Requires Geo::Coder::Mapquest 0.05 or above
sub _MIN_MODULE_VERSION { return '0.05'; }

=head1 SYNOPSIS

This module adds Mapquest support to Geo::Coder::Many.

Use as follows:

    use Geo::Coder::Many;
    use Geo::Coder::Mapquest;
    
    my $options = { };
    my $geocoder_many = Geo::Coder::Many->new( $options );
    my $MQ = Geo::Coder::Mapquest->new(apikey => 'Your API key');
    
    my $options = {
        geocoder    => $MQ,
    };
    
    $geocoder_many->add_geocoder( $options );
    
    my $location = $geocoder_many->geocode( 
        {
            location => '82 Clerkenwell Road, London, EC1M 5RF'
        }
    );

=head1 MORE INFO

please see http://search.cpan.org/dist/Geo-Coder-Mapquest/ 
and http://developer.mapquest.com/web/products/dev-services/geocoding-ws

=head1 SUBROUTINES/METHODS

=head2 geocode

This is called by Geo::Coder::Many - it sends the geocoding request (via
Geo::Coder::Mapquest) and extracts the resulting location, returning it in a
standard Geo::Coder::Many::Response.

NOTE: currently precision is hard coded to undef! We need to fix it to
interpret the code returned by mapquest and assigning a meaningful
precision

=cut

sub geocode {
    my $self     = shift;
    my $location = shift;
    defined $location or croak "Geo::Coder::Many::Mapquest::geocode 
                                method must be given a location.";

    my @raw_replies = $self->{GeoCoder}->geocode( location => $location );
    my $response = Geo::Coder::Many::Response->new( { location => $location } );

    foreach my $raw_reply ( @raw_replies ) {


        # need to determine precision from response code
        my $precision = 
	    $self->_determine_precision($raw_reply->{geocodeQualityCode});

        my $tmp = {
              address     => $raw_reply->{display_name},
              country     => $raw_reply->{adminArea1},
              longitude   => $raw_reply->{latLng}->{lng},
              latitude    => $raw_reply->{latLng}->{lat},
              precision   => $precision,
        };
        $response->add_response( $tmp, $self->get_name() );
    }

    my $http_response = $self->{GeoCoder}->response();
    $response->set_response_code($http_response->code());
    return $response;
}

sub _determine_precision {
    my $self = shift;
    my $code = shift;

    my $precision = undef; # FIXME!
    # for now all precision set to undef (ie we dont know)
    # should instead be converting to meaningful number between 0 and 1
    # based on code
    # see http://www.mapquestapi.com/geocoding/geocodequality.html
    return $precision; 
}

=head2 get_name

Returns the name of the geocoder type - used by Geo::Coder::Many

=cut

sub get_name { my $self = shift; return 'mapquest ' . $self->{GeoCoder}->VERSION; }

1; 

__END__
