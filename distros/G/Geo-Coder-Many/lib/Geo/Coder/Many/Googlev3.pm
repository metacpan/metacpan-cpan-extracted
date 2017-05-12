package Geo::Coder::Many::Googlev3;

use strict;
use warnings;
use Carp;
use Geo::Coder::Many::Util;
use base 'Geo::Coder::Many::Generic';

=head1 NAME

Geo::Coder::Many::Googlev3 - Plugin for version 3 of the google maps geocoder

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

# Requires Geo::Coder::Googlev3 0.07 or above
sub _MIN_MODULE_VERSION { return '0.07'; }

=head1 SYNOPSIS

This class wraps Geo::Coder::Googlev3 such that it can be used in
Geo::Coder::Many, by converting the results to a standard form.

Note: this module supports v3 of the Google geocoder. There is also
Geo::Coder::Google (also supported by Geo::Coder::Many) which supports
the older version 2.

=head1 METHODS

=head2 geocode

Takes a location string, geocodes it using Geo::Coder::Googlev3, and returns the
result in a form understandable to Geo::Coder::Many

=cut

# see details of Google's response format here:
# v3: http://code.google.com/apis/maps/documentation/geocoding/

sub geocode {
    my $self = shift;
    my $location = shift;
    defined $location or croak "Geo::Coder::Many::Googlev3::geocode 
                                method must be given a location.";

    my $raw = $self->{GeoCoder}->geocode( location => $location,
                                          raw      => 1,
                                        );
    # was there a response
    if (!defined($raw)){
        carp "no response from googlev3 when requesting $location";
	return;
    }

    # was response any good?
    if ($raw->{status} ne 'OK'){
        # carp $raw->{status} . " when requesting $location";
	return;
    }

    my $Response = Geo::Coder::Many::Response->new({ location => $location});

    foreach my $raw_reply ( @{$raw->{results}} ){
	my $precision = 0; # unknown

	if (defined($raw_reply->{geometry}) 
	    && defined($raw_reply->{geometry}{viewport}) ){
	    
	    my $box = $raw_reply->{geometry}{viewport};
	    # lng and lat in decimal degree format            
	    
	    $precision = 
		Geo::Coder::Many::Util::determine_precision_from_bbox({
		    'lon1' => $box->{southwest}{lng},
		    'lat1' => $box->{southwest}{lat},
		    'lon2' => $box->{northeast}{lng},
		    'lat2' => $box->{northeast}{lat},
                });

	}
	# which country?
	# need to scan the address components
	my $country = undef;
	foreach my $rh_address_component (@{$raw_reply->{address_components}}){
	    my $ra_types = $rh_address_component->{types};
	    my $p = 0;
	    my $c = 0;
	    foreach my $x (@$ra_types){
		$p = 1 if ($x eq 'political');
		$c = 1 if ($x eq 'country');
		if ($c && $p){
		    $country = $rh_address_component->{long_name};
		}
	    }
	}

	my $tmp = {
	    address   => $raw_reply->{formatted_address},
	    country   => $country,
	    latitude  => $raw_reply->{geometry}{location}{lat},
	    longitude => $raw_reply->{geometry}{location}{lng},
	    precision => $precision,
	};
	$Response->add_response( $tmp, $self->get_name());
    }
    return $Response;
}

=head2 get_name

The short name by which Geo::Coder::Many can refer to this geocoder.

=cut

sub get_name { my $self = shift; return 'googlev3 ' . $self->{GeoCoder}->VERSION; }

1;
