package Geo::Coder::US::Census;

use strict;
use warnings;

use Carp;
use Encode;
use JSON::MaybeXS;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use URI;
use Geo::StreetAddress::US;

=head1 NAME

Geo::Coder::US::Census - Provides a Geo-Coding functionality for the US using L<https://geocoding.geo.census.gov>

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

      use Geo::Coder::US::Census;

      my $geo_coder = Geo::Coder::US::Census->new();
      # Get geocoding results (as a hash decoded from JSON)
      my $location = $geo_coder->geocode(location => '4600 Silver Hill Rd., Suitland, MD');
      # Sometimes the server gives a 500 error on this
      $location = $geo_coder->geocode(location => '4600 Silver Hill Rd., Suitland, MD, USA');

=head1 DESCRIPTION

Geo::Coder::US::Census provides geocoding functionality specifically for U.S. addresses by interfacing with the U.S. Census Bureau's geocoding service.
It allows developers to convert street addresses into geographical coordinates (latitude and longitude) by querying the Census Bureau's API.
Using L<LWP::UserAgent> (or a user-supplied agent), the module constructs and sends an HTTP GET request to the API.

The module uses L<Geo::StreetAddress::US> to break down a given address into its components (street, city, state, etc.),
ensuring that the necessary details for geocoding are present.

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::US::Census->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::US::Census->new(ua => $ua);

=cut

sub new {
	my $class = $_[0];

	shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $ua = $args{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
		$ua->env_proxy(1);
	}
	my $host = $args{host} || 'geocoding.geo.census.gov/geocoder/locations/address';

	return bless { ua => $ua, host => $host, %args }, $class;
}

=head2 geocode

Geocode an address.
It accepts addresses provided in various forms -
whether as a single argument, a key/value pair, or within a hash reference -
making it easy to integrate into different codebases.
It decodes the JSON response from the API using L<JSON::MaybeXS>,
providing the result as a hash.
This allows easy extraction of latitude, longitude, and other details returned by the service.

    $location = $geo_coder->geocode(location => $location);
    # @location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

=cut

sub geocode {
	my $self = shift;
	my %param;

	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: geocode(location => $location)');
	} elsif(@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{location} = shift;
	}

	my $location = $param{location}
		or Carp::croak('Usage: geocode(location => $location)');

	if (Encode::is_utf8($location)) {
		$location = Encode::encode_utf8($location);
	}

	if($location =~ /,?(.+),\s*(United States|US|USA)$/i) {
		$location = $1;
	}

	# Remove county from the string, if that's included
	# Assumes not more than one town in a state with the same name
	# in different counties - but the census Geo-Coding doesn't support that
	# anyway
	# Some full state names include spaces, e.g South Carolina
	# Some roads include full stops, e.g. S. West Street
	if($location =~ /^(\d+\s+[\w\s\.]+),\s*([\w\s]+),\s*[\w\s]+,\s*([A-Za-z\s]+)$/) {
		$location = "$1, $2, $3";
	}

	my $uri = URI->new("https://$self->{host}");
	my $hr = Geo::StreetAddress::US->parse_address($location);

	if((!defined($hr->{'city'})) || (!defined($hr->{'state'}))) {
		# use Data::Dumper;
		# print Data::Dumper->new([$hr])->Dump(), "\n";
		Carp::carp(__PACKAGE__ . ": city and state are mandatory ($location)");
		return;
	}

	my %query_parameters = (
		'benchmark' => 'Public_AR_Current',
		'city' => $hr->{'city'},
		'format' => 'json',
		'state' => $hr->{'state'},
	);
	if($hr->{'street'}) {
		if($hr->{'number'}) {
			$query_parameters{'street'} = $hr->{'number'} . ' ' . $hr->{'street'} . ' ' . $hr->{'type'};
		} else {
			$query_parameters{'street'} = $hr->{'street'} . ' ' . $hr->{'type'};
		}
		if($hr->{'suffix'}) {
			$query_parameters{'street'} .= ' ' . $hr->{'suffix'};
		}
	}

	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();

	my $res = $self->{ua}->get($url);

	if($res->is_error()) {
		Carp::carp("$url API returned error: " . $res->status_line());
		return;
	}

	my $json = JSON::MaybeXS->new->utf8();
	return $json->decode($res->decoded_content());

	# my @results = @{ $data || [] };
	# wantarray ? @results : $results[0];
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

  $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

  $geo_coder->ua(LWP::UserAgent::Throttled->new());

=cut

sub ua {
	my $self = shift;
	if (@_) {
		$self->{ua} = shift;
	}
	$self->{ua};
}

=head2 reverse_geocode

    # $location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');

# Similar to geocode except it expects a latitude/longitude parameter.

Not supported.
Croaks if this method is called.

=cut

sub reverse_geocode {
	# my $self = shift;

	# my %param;
	# if (@_ % 2 == 0) {
		# %param = @_;
	# } else {
		# $param{latlng} = shift;
	# }

	# my $latlng = $param{latlng}
		# or Carp::croak("Usage: reverse_geocode(latlng => \$latlng)");

	# return $self->geocode(location => $latlng, reverse => 1);
	Carp::croak(__PACKAGE__, ': Reverse geocode is not supported');
}

=head2 run

In addition to being used as a library within other Perl scripts,
L<Geo::Coder::US::Census> can be run directly from the command line.
When invoked this way,
it accepts an address as input,
performs geocoding,
and prints the resulting data structure via L<Data::Dumper>.

    perl Census.pm 1600 Pennsylvania Avenue NW, Washington DC

=cut

__PACKAGE__->run(@ARGV) unless caller();

sub run {
	require Data::Dumper;

	my $class = shift;

	my $location = join(' ', @_);

	my @rc = $class->new()->geocode($location);

	die "$0: geocoding failed" unless(scalar(@rc));

	print Data::Dumper->new([\@rc])->Dump();
}

=head1 AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on L<Geo::Coder::GooglePlaces>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocoding.geo.census.gov.

=head1 BUGS

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

https://www.census.gov/data/developers/data-sets/Geocoding-services.html

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
