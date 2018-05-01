package Geo::Coder::XYZ;

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

Geo::Coder::XYZ - Provides a geocoding functionality using https://geocode.xyz

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

      use Geo::Coder::XYZ;

      my $geocoder = Geo::Coder::XYZ->new();
      my $location = $geocoder->geocode(location => '10 Downing St., London, UK');

=head1 DESCRIPTION

Geo::Coder::XYZ provides an interface to geocode.xyz, a free geocode database covering many countries.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::XYZ->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoder = Geo::Coder::XYZ->new(ua => $ua);

=cut

sub new {
	my($class, %param) = @_;

	my $ua = delete $param{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	if(!defined($param{'host'})) {
		$ua->ssl_opts(verify_hostname => 0);	# Yuck
	}
	my $host = delete $param{host} || 'geocode.xyz';

	return bless { ua => $ua, host => $host }, $class;
}

=head2 geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

    @locations = $geocoder->geocode('Portland, USA');
    diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

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

	my $uri = URI->new("https://$self->{host}/");
	if($location =~ /(.+),\s*England$/i) {
		$location = "$1, United Kingdom";	# geocode.xyz gets confused between England and New England
	}
	$location =~ s/\s/+/g;
	my %query_parameters = ('locate' => $location, 'json' => 1);
	if(wantarray) {
		# moreinfo is needed to find alternatives when the given location is ambiguous
		$query_parameters{'moreinfo'} = 1;
	}
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();

	my $res = $self->{ua}->get($url);

	if ($res->is_error) {
		Carp::carp("API returned error: on $url " . $res->status_line());
		return { };
	}

	my $json = JSON->new()->utf8();
	my $rc;
	eval {
		$rc = $json->decode($res->content());
	};
	if(!defined($rc)) {
		if($@) {
			Carp::carp("$url: $@");
			return { };
		}
		Carp::carp("$url: can't decode the JSON ", $res->content());
		return { };
	}

	if($rc->{'otherlocations'} && $rc->{'otherlocations'}->{'loc'} &&
	   (ref($rc->{'otherlocations'}->{'loc'}) eq 'ARRAY')) {
		my @rc = @{$rc->{'otherlocations'}->{'loc'}};
	   	if(wantarray) {
			return @rc;
		}
		return $rc[0];
	}
	return $rc;

	# my @results = @{ $data || [] };
	# wantarray ? @results : $results[0];
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    $geocoder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
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
		or Carp::carp("Usage: reverse_geocode(latlng => \$latlng)");

	return $self->geocode(location => $latlng, reverse => 1);
}

=head1 AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on L<Geo::Coder::Coder::Googleplaces>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocode.xyz.

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2018 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
