package Geo::Coder::Postcodes;

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

Geo::Coder::Postcodes - Provides a geocoding functionality using L<https://postcodes.io>.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

      use Geo::Coder::Postcodes;

      my $geo_coder = Geo::Coder::Postcodes->new();
      my $location = $geo_coder->geocode(location => 'Margate');

=head1 DESCRIPTION

Geo::Coder::Postcodes provides an interface to postcodes.io,
a free Geo-Coder database covering the towns in the UK.

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::Postcodes->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::Postcodes->new(ua => $ua);

=cut

sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	if(!defined($class)) {
		# Geo::Coder::Postcodes::new() used rather than Geo::Coder::Postcodes->new()
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
	}

	my $ua = delete $args{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	# if(!defined($args{'host'})) {
		# $ua->ssl_opts(verify_hostname => 0);	# Yuck
	# }
	my $host = delete $args{host} || 'api.postcodes.io';

	return bless { ua => $ua, host => $host, %args }, $class;
}

=head2 geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'logitude'}, "\n";

=cut

sub geocode {
	my $self = shift;

	scalar(@_) > 0 or
		Carp::croak('Usage: geocode(location => $location)');

	my %param;
	if (@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{location} = shift;
	}

	my $location = $param{location};
	unless(defined($location)) {
		Carp::croak('Usage: geocode(location => $location)');
		return;
	}

	my $county;
	if($location =~ /,/) {
		if($location =~ /^([\w\s\-]+?),([\w\s]+?),[\w\s]+?$/i) {
			# Turn 'Ramsgate, Kent, UK' into 'Ramsgate'
			$location = $1;
			$county = $2;
			$county =~ s/^\s//g;
			$county =~ s/\s$//g;
		} else {
			Carp::croak('Postcodes.io only supports towns, not full addresses');
			return;
		}
	}
	$location =~ s/\s/+/g;

	if(Encode::is_utf8($location)) {
		$location = Encode::encode_utf8($location);
	}

	my $uri = URI->new("https://$self->{host}/places/");
	my %query_parameters = ('q' => $location);
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();
	$url =~ s/%2B/+/g;

	my $res = $self->{ua}->get($url);

	if($res->is_error) {
		Carp::croak("postcodes.io API returned error: on $url " . $res->status_line());
		return;
	}

	my $json = JSON::MaybeXS->new()->utf8();

	# TODO: wantarray
	my $rc = $json->decode($res->decoded_content());
	my @results = @{$rc->{result}};
	if($county) {
		# TODO: search through all results for the right one, e.g. Leeds in
		#	Kent or in West Yorkshire?
		foreach my $result(@results) {
			# if(defined($result->{'county_unitary'}) && ($result->{'county_unitary_type'} eq 'County')) {
			if(my $unitary = $result->{'county_unitary'}) {
				# $location =~ s/+/ /g;
				if(($unitary =~ /$county/i) || ($unitary =~ /$location/i)) {
					return $result;
				}
			}
			if((my $region = $result->{'region'}) && ($county =~ /\s+(\w+)$/)) {
				if($region =~ /$1/) {
					# e.g. looked for South Yorkshire, got Yorkshire and the Humber
					return $result;
				}
			}
		}
		return;
	}
	return $results[0];
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
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

    $location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

=cut

sub reverse_geocode {
	my $self = shift;

	scalar(@_) > 0 or
		Carp::croak('Usage: reverse_geocode(latlng => $latlng)');

	my %param;
	if (@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{latlng} = shift;
	}

	my $latlng = $param{latlng};
	unless(defined($latlng)) {
		Carp::croak('Usage: reverse_geocode(latlng => $latlng)');
		return;
	}

	my $uri = URI->new("https://$self->{host}/postcodes/");
	my ($lat, $lon) = split(/,/, $param{latlng});
	my %query_parameters = ('lat' => $lat, 'lon' => $lon, radius => '1000');
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string;

	my $res = $self->{ua}->get($url);

	if ($res->is_error) {
		Carp::croak("postcodes.io API returned error: on $url " . $res->status_line());
		return;
	}

	my $json = JSON::MaybeXS->new->utf8();

	my $rc = $json->decode($res->content);
	if($rc->{'result'}) {
		my @results = @{$rc->{'result'}};
		return $results[0];
	}
	return;
}

=head1 BUGS

Note that this most only works on towns and cities, some searches such as "Margate, Kent, UK"
may work, but you're best to search only for "Margate".

=head1 AUTHOR

Nigel Horne C<< <njh@bandsman.co.uk> >>

Based on L<Geo::Coder::GooglePlaces>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at postcodes.io.

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
