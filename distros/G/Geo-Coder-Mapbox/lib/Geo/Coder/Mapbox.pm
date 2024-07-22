package Geo::Coder::Mapbox;

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

Geo::Coder::Mapbox - Provides a Geo-Coding functionality using L<https://mapbox.com>

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Geo::Coder::Mapbox;

    my $geo_coder = Geo::Coder::Mapbox->new(access_token => $ENV{'MAPBOX_KEY'});
    my $location = $geo_coder->geocode(location => 'Washington, DC');

=head1 DESCRIPTION

Geo::Coder::Mapbox provides an interface to mapbox.com, a Geo-Coding database covering many countries.

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::Mapbox->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::Mapbox->new(ua => $ua);

=cut

sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# Use Geo::Coder::Mapbox->new(), not Geo::Coder::Mapbox::new()
	if(!defined($class)) {
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	my $ua = $args{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	# if(!defined($args{'host'})) {
		# $ua->ssl_opts(verify_hostname => 0);	# Yuck
	# }
	my %defaults = (
		host => 'api.mapbox.com',
		access_token => ''
	);

	# Re-seen keys take precedence, so defaults come first
	return bless { %defaults, %args, ua => $ua }, $class;
}

=head2 geocode

    $location = $geo_coder->geocode(location => 'Toronto, Ontario, Canada');

    print 'Latitude: ', $location->{features}[0]->{center}[1], "\n";	# Latitude
    print 'Longitude: ', $location->{features}[0]->{center}[0], "\n";	# Longitude

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

	my $uri = URI->new("https://$self->{host}/geocoding/v5/mapbox.places/$location.json");
	$location =~ s/\s/+/g;
	my %query_parameters = ('access_token' => $self->{'access_token'});
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();

	# ::diag($url);

	my $res = $self->{ua}->get($url);

	if ($res->is_error) {
		Carp::carp("API returned error: on $url ", $res->status_line());
		return { };
	}

	my $json = JSON::MaybeXS->new()->utf8();
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

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'api.mapbox.com' => 2 });
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

    $location = $geo_coder->reverse_geocode(lnglat => '-122.39732,37.778907');

Similar to geocode except it expects a longitude/latitude (note the order) parameter.

=cut

sub reverse_geocode {
	my $self = shift;

	my %param;
	if (@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{lnglat} = shift;
	}

	my $lnglat = $param{lnglat}
		or Carp::carp('Usage: reverse_geocode(location => $lnglat)');

	# return $self->geocode(location => $lnglat, reverse => 1);
	return $self->geocode(location => $lnglat);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

Based on L<Geo::Coder::GooglePlaces>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at mapbox.com.

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>, L<https://docs.mapbox.com/api/search/geocoding/>

=head1 LICENSE AND COPYRIGHT

Copyright 2021-2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
