package Geo::Coder::CA;

use strict;
use warnings;

use Carp;
use Encode;
use JSON;
use HTTP::Request;
use LWP::UserAgent;
use URI;

=head1 NAME

Geo::Coder::CA - Provides a geocoding functionality using http:://geocoder.ca for both Canada and the US.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

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

	my $ua	   = delete $param{ua}	   || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	my $host	 = delete $param{host}	 || 'geocoder.ca';

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
	my %query_parameters = ('locate' => $location);
	$query_parameters{json} = 1;
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string;

	my $res = $self->{ua}->get($url);

	if ($res->is_error) {
		Carp::croak("Google Places API returned error: " . $res->status_line);
	}

	my $json = JSON->new->utf8;
	return $json->decode($res->content);	# No support for list context, yet

	# my @results = @{ $data || [] };
	# wantarray ? @results : $results[0];
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

  $geocoder->ua()->env_proxy(1);

You can also set your own User-Agent object:

  $geocoder->ua(LWPx::ParanoidAgent->new());

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

# method below adapted from
# http://gmaps-samples.googlecode.com/svn/trunk/urlsigning/urlsigner.pl
sub _encode_urlsafe{
	my ($self, $content) = @_;
	$content =~ tr/\+/\-/;
	$content =~ tr/\//\_/;

	return $content;
}

=head1 AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on L<Geo::Coder::Coder::Googleplaces>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocoder.ca.

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
