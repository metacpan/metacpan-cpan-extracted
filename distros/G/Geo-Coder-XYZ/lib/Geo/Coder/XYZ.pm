package Geo::Coder::XYZ;

use strict;
use warnings;

use Carp;
use Encode;
use JSON::MaybeXS;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use Params::Get;
use URI;

=head1 NAME

Geo::Coder::XYZ - Provides a Geo-Coding functionality using L<https://geocode.xyz>

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

      use Geo::Coder::XYZ;

      my $geo_coder = Geo::Coder::XYZ->new();
      my $location = $geo_coder->geocode(location => '10 Downing St., London, UK');

=head1 DESCRIPTION

Geo::Coder::XYZ provides an interface to geocode.xyz, a free Geo-Coding database covering many countries.

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::XYZ->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::XYZ->new(ua => $ua);

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Use Geo::Coder::XYZ->new(), not Geo::Coder::XYZ::new()
	if(!defined($class)) {
		carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		return;
	}

	my $params = Params::Get::get_params(undef, \@_);

	my $ua = $params->{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
	}
	if(!defined($params->{'host'})) {
		$ua->ssl_opts(verify_hostname => 0);	# Yuck
	}
	my $host = $params->{host} || 'geocode.xyz';

	return bless { ua => $ua, host => $host }, $class;
}

=head2 geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

    @locations = $geo_coder->geocode('Portland, USA');
    print 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations), "\n";

=cut

sub geocode {
	my $self = shift;
	my $params = Params::Get::get_params('location', \@_);

	my $location = $params->{location}
		or Carp::croak('Usage: geocode(location => $location)');

	# Fail when the input is just a set of numbers
	if($params->{'location'} !~ /\D/) {
		Carp::croak('Usage: ', __PACKAGE__, ": invalid input to geocode(), $params->{location}");
		return;
	}

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
		Carp::carp("API returned error: on $url ", $res->status_line());
		return { };
	}

	my $json = JSON::MaybeXS->new()->utf8();
	my $rc;
	eval {
		$rc = $json->decode($res->decoded_content());
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

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'geocode.xyz' => 2 });
    $geo_coder->ua($ua);

=cut

sub ua {
	my $self = shift;
	if (@_) {
		$self->{ua} = shift;
	}
	$self->{ua};
}

=head2 reverse_geocode

    $location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

=cut

sub reverse_geocode
{
	my $self = shift;
	my $params = Params::Get::get_params('latlng', \@_);

	my $latlng = $params->{'latlng'}
		or Carp::carp('Usage: reverse_geocode(latlng => $latlng)');

	return $self->geocode(location => $latlng, reverse => 1);
}

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Based on L<Geo::Coder::GooglePlaces>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocode.xyz.

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
