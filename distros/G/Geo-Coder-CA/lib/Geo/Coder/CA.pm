package Geo::Coder::CA;

# See also https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html for the US for the future

use strict;
use warnings;

use Carp;
use Encode;
use JSON;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use URI;

=head1 NAME

Geo::Coder::CA - Provides a geocoding functionality using http:://geocoder.ca for both Canada and the US.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

      use Geo::Coder::CA;

      my $geocoder = Geo::Coder::CA->new();
      my $location = $geocoder->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');

=head1 DESCRIPTION

Geo::Coder::CA provides an interface to geocoder.ca.  Geo::Coder::Canada no longer seems to work.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::CA->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoder = Geo::Coder::CA->new(ua => $ua);

=cut

sub new {
	my($class, %param) = @_;

	my $ua = delete $param{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	my $host = delete $param{host} || 'geocoder.ca';

	return bless { ua => $ua, host => $host }, $class;
}

=head2 geocode

    $location = $geocoder->geocode(location => $location);
    # @location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

=cut

sub geocode {
	my $self = shift;

	my %param;
	if (@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{location} = shift;
	}

	my $location = $param{location}
		or Carp::croak("Usage: geocode(location => \$location)");

	if (Encode::is_utf8($location)) {
		$location = Encode::encode_utf8($location);
	}

	my $uri = URI->new("https://$self->{host}/some_location");
	$location =~ s/\s/+/g;
	my %query_parameters = ('locate' => $location, 'json' => 1, 'strictmode' => 1);
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();

	my $res = $self->{ua}->get($url);

	if($res->is_error()) {
		Carp::croak("geocoder.ca API returned error: " . $res->status_line());
		return;
	}

	my $json = JSON->new->utf8();
	my $rc = $json->decode($res->content());
	if($rc && $rc->{'latt'} && $rc->{'longt'}) {
		return $rc;	# No support for list context, yet
	}

	# if($location =~ /^(\w+),\+*(\w+),\+*(USA|US|United States)$/i) {
		# $query_parameters{'locate'} = "$1 County, $2, $3";
		# $uri->query_form(%query_parameters);
		# $url = $uri->as_string();
# 
		# $res = $self->{ua}->get($url);
# 
		# if($res->is_error()) {
			# Carp::croak("geocoder.ca API returned error: " . $res->status_line());
			# return;
		# }
		# return $json->decode($res->content());
	# }
	return;

	# my @results = @{ $data || [] };
	# wantarray ? @results : $results[0];
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

  $geocoder->ua()->env_proxy(1);

You can also set your own User-Agent object:

  $geocoder->ua(LWP::UserAgent::Throttled->new());

=cut

sub ua {
	my $self = shift;
	if (@_) {
		$self->{ua} = shift;
	}
	$self->{ua};
}

=head2 reverse_geocode

    $location = $geocoder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

=cut

sub reverse_geocode {
	my $self = shift;

	my %param;
	if (@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{latlng} = shift;
	}

	my $latlng = $param{latlng}
		or Carp::croak("Usage: reverse_geocode(latlng => \$latlng)");

	return $self->geocode(location => $latlng, reverse => 1);
};

=head2 run

You can also run this module from the command line:

    perl CA.pm 1600 Pennsylvania Avenue NW, Washington DC

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

Based on L<Geo::Coder::Coder::Googleplaces>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocoder.ca.

=head1 BUGS

Should be called Geo::Coder::NA for North America.

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
