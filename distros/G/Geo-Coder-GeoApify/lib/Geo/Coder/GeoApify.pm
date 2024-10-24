package Geo::Coder::GeoApify;

use strict;
use warnings;

use Carp;
use Encode;
use JSON::MaybeXS;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use URI;

=head1 NAME

Geo::Coder::GeoApify - Provides a Geo-Coding functionality using L<https://www.geoapify.com/maps-api/>

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Geo::Coder::GeoApify;

    my $geo_coder = Geo::Coder::GeoApify->new(apiKey => $ENV{'GEOAPIFY_KEY'});
    my $location = $geo_coder->geocode(location => '10 Downing St., London, UK');

=head1 DESCRIPTION

Geo::Coder::GeoApify provides an interface to https://www.geoapify.com/maps-api/,
a free Geo-Coding database covering many countries.

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::GeoApify->new(apiKey => 'foo');

=cut

sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# Use Geo::Coder::GeoApify->new(), not Geo::Coder::GeoApify::new()
	if(!defined($class)) {
		carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		return;
	}

	if(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	my $apiKey = $args{'apiKey'};
	if(!defined($apiKey)) {
		carp(__PACKAGE__, ' apiKey not given');
		return;
	}

	my $ua = $args{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
	}
	if(!defined($args{'host'})) {
		$ua->ssl_opts(verify_hostname => 0);	# Yuck
	}
	my $host = delete $args{host} || 'api.geoapify.com/v1/geocode';

	return bless { ua => $ua, host => $host, apiKey => $args{'apiKey'} }, $class;
}

=head2 geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'features'}[0]{'geometry'}{'coordinates'}[1], "\n";
    print 'Longitude: ', $location->{'features'}[0]{'geometry'}{'coordinates'}[0], "\n";

    @locations = $geo_coder->geocode('Portland, USA');
    print 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations), "\n";

=cut

sub geocode {
	my $self = shift;
	my %param;

	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: geocode(location => $location)');
		return;	# Not sure why this is needed, but t/carp.t fails without it
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

	my $uri = URI->new("https://$self->{host}/search");
	if($location =~ /(.+),\s*England$/i) {
		$location = "$1, United Kingdom";	# Avoid confusion between England and New England
	}
	$location =~ s/\s/+/g;
	my %query_parameters = ('text' => $location, 'apiKey' => $self->{'apiKey'});
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

	return $rc;
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new({ 'api.geoapify.com' => 2 });
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::GeoApify->new({ ua => $ua, apiKey => 'foo' });

=cut

sub ua {
	my $self = shift;
	if (@_) {
		$self->{ua} = shift;
	}
	$self->{ua};
}

=head2 reverse_geocode

    my $address = $geo_coder->reverse_geocode(lat => 37.778907, lon => -122.39732);
    print 'City: ', $address->{features}[0]->{'properties'}{'city'}, "\n";

Similar to geocode except it expects a latitude,longitude pair.

=cut

sub reverse_geocode {
	my $self = shift;
	my %param;

	if(ref($_[0]) eq 'HASH') {
		%param = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak('Usage: geocode(location => $location)');
		return;	# Not sure why this is needed, but t/carp.t fails without it
	} elsif((@_ % 2) == 0) {
		%param = @_;
	}

	my $lat = $param{lat}
		or Carp::carp('Usage: reverse_geocode(lat => $lat, lon => $lon');

	my $lon = $param{lon}
		or Carp::carp('Usage: reverse_geocode(lat => $lat, lon => $lon');

	my $uri = URI->new("https://$self->{host}/reverse");
	my %query_parameters = ('lat' => $lat, 'lon' => $lon, 'apiKey' => $self->{'apiKey'});
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

	return $rc;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geoapify.com

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
