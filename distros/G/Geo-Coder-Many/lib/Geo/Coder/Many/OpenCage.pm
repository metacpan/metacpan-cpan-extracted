package Geo::Coder::Many::OpenCage;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Geo::Coder::Many::Util;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::OpenCage - OpenCage plugin for Geo::Coder::Many

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

# Requires Geo::Coder::OpenCage 0.01 or above
sub _MIN_MODULE_VERSION { return '0.02'; }

=head1 SYNOPSIS

This module adds OpenCage Geocoder support to Geo::Coder::Many.

Use as follows:

  use Geo::Coder::Many;
  use Geo::Coder::OpenCage;
  my $options = { };
  my $geocoder_many = Geo::Coder::Many->new( $options );
  my $OC = Geo::Coder::OpenCage->new( api_key => $my_OC_api_key );

  my $OC_options = {
      geocoder    => $OC,
      daily_limit => 2500,
  };

  $geocoder_many->add_geocoder( $OC_options );
  my $location = $geocoder_many->geocode({ 
      location => '82 Clerkenwell Road, London, EC1M 5RF',
  });

=head1 USAGE POLICY

See http://geocoder.opencagedata.com

=head1 SUBROUTINES/METHODS

=head2 geocode

This is called by Geo::Coder::Many - it sends the geocoding request 
(via L<Geo::Coder::OpenCage>) and extracts the resulting location, returning it 
in a standard Geo::Coder::Many::Response.

=cut

sub geocode {
    my $self = shift;
    my $location = shift;
    defined $location 
        or croak "Geo::Coder::Many::OpenCage::geocode must be given location.";

    my $rh_response = $self->{GeoCoder}->geocode( location => $location );
    my $response = Geo::Coder::Many::Response->new({ location => $location });

    my $location_data = [];
        
    foreach my $raw_reply ( @{ $rh_response->{results} } ){
        my $precision = 0; # unknown
        if (defined($raw_reply->{bounds})){

            $precision =
                Geo::Coder::Many::Util::determine_precision_from_bbox({
                            'lon1' => $raw_reply->{bounds}{northeast}{lng},
                            'lat1' => $raw_reply->{bounds}{northeast}{lat},
                            'lon2' => $raw_reply->{bounds}{southwest}{lng},
                            'lat2' => $raw_reply->{bounds}{southwest}{lng},
                 });
        } else {
            $precision = $raw_reply->{confidence};
        }
        
        my $tmp = {
              address   => $raw_reply->{formatted},
              country   => $raw_reply->{components}{country},
              longitude => $raw_reply->{geometry}{lng},
              latitude  => $raw_reply->{geometry}{lat},
              precision => $precision,
        };

        $response->add_response( $tmp, $self->get_name() );
    }

    if (defined($rh_response)){
        #print STDERR Dumper $rh_response;
        $response->set_response_code($rh_response->{status}->{code});
    } else {
        $response->set_response_code(401);        
    }
    return $response;
}

=head2 get_name

Returns the name of the geocoder type - used by Geo::Coder::Many

=cut

sub get_name { 
    my $self = shift; 
    return 'opencage ' . $VERSION;
}

1; # End of Geo::Coder::Many::OpenCage
