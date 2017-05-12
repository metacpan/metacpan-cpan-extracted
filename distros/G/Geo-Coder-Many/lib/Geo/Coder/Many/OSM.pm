package Geo::Coder::Many::OSM;

use warnings;
use strict;
use Carp;
use Geo::Coder::Many::Util;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::OSM - OpenStreetMap Nominatim plugin for Geo::Coder::Many

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

# Requires Geo::Coder::OSM 0.01 or above
sub _MIN_MODULE_VERSION { return '0.01'; }

=head1 SYNOPSIS

This module adds OpenStreetMap Nominatim support to Geo::Coder::Many.

Use as follows:

    use Geo::Coder::Many;
    use Geo::Coder::OSM;
    
    my $options = { };
    my $geocoder_many = Geo::Coder::Many->new( $options );
    my $osm = Geo::Coder::OSM->new;
    
    my $osm_options = {
        geocoder    => $osm,
    # This limit should not be taken as necessarily valid. 
    # Please check the Nominatim usage policy.
        daily_limit => 5000,
    };
    
    $geocoder_many->add_geocoder( $osm_options );
    
    my $location = $geocoder_many->geocode( 
        {
            location => '82 Clerkenwell Road, London, EC1M 5RF'
        }
    );

=head1 USAGE POLICY

Be careful to limit the number of requests you send, or risk being blocked.

See http://wiki.openstreetmap.org/wiki/Nominatim#Usage_Policy for details.

=head1 SUBROUTINES/METHODS

=head2 geocode

This is called by Geo::Coder::Many - it sends the geocoding request (via
Geo::Coder::OSM) and extracts the resulting location, returning it in a
standard Geo::Coder::Many::Response.

=cut

sub geocode {
    my $self     = shift;
    my $location = shift;
    defined $location or croak "Geo::Coder::Many::OSM::geocode 
                                method must be given a location.";

    my @raw_replies = $self->{GeoCoder}->geocode( location => $location );
    my $response = Geo::Coder::Many::Response->new( { location => $location } );

    my $location_data = [];

    foreach my $raw_reply ( @raw_replies ) {

        my $precision = 0; # unknown
        if (defined($raw_reply->{boundingbox})){
	    my $ra_bbox = $raw_reply->{boundingbox};

	    $precision = 
                Geo::Coder::Many::Util::determine_precision_from_bbox({
  	                    'lon1' => $ra_bbox->[0],
                            'lat1' => $ra_bbox->[2],
                            'lon2' => $ra_bbox->[1],
                            'lat2' => $ra_bbox->[3],
                 });
	}
        my $tmp = {
              address     => $raw_reply->{display_name},
              country     => $raw_reply->{address}{country},
              longitude   => $raw_reply->{lon},
              latitude    => $raw_reply->{lat},
              precision   => $precision,
        };

        $response->add_response( $tmp, $self->get_name() );
    };

    my $http_response = $self->{GeoCoder}->response();
    $response->set_response_code($http_response->code());

    return $response;
}

=head2 get_name

Returns the name of the geocoder type - used by Geo::Coder::Many

=cut

sub get_name { my $self = shift; return 'osm ' . $self->{GeoCoder}->VERSION; }

1; # End of Geo::Coder::Many::OSM
