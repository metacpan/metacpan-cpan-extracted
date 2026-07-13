#!/usr/bin/env perl

use strict;
use warnings;

use Readonly;
use Test::Mockingbird qw(mock restore_all);
use Test::Most;

BEGIN { use_ok('HTML::OSM') }

Readonly my %C => (
	LAT_NY => 40.7128,
	LON_NY => -74.0060,
	LAT_SF => 37.7749,
	LON_SF => -122.4194,
);

# Block real network calls for the whole file.
{
	my $fail_resp = bless {}, 'MockNetResp';
	mock 'MockNetResp::is_success' => sub { 0 };
	my $fail_ua = bless {}, 'MockNetUA';
	mock 'MockNetUA::default_header' => sub { };
	mock 'MockNetUA::env_proxy'      => sub { };
	mock 'MockNetUA::get'            => sub { $fail_resp };
	mock 'LWP::UserAgent::new'       => sub { $fail_ua };
}

# Install geocode() before constructing the object so that
# Params::Validate::Strict can verify geocoder->can('geocode').
mock 'MockGeocoder::geocode' => sub {
	my ($self, $address) = @_;
	return { lat => $C{LAT_NY}, lon => $C{LON_NY} } if $address eq 'New York, NY';
	return { lat => $C{LAT_SF}, lon => $C{LON_SF} } if $address eq 'San Francisco, CA';
	return undef;
};

my $geocoder = bless {}, 'MockGeocoder';
my $osm      = HTML::OSM->new(geocoder => $geocoder);

subtest '_fetch_coordinates: known address returns correct lat/lon pair' => sub {
	my @got = $osm->_fetch_coordinates('New York, NY');
	is_deeply(\@got, [$C{LAT_NY}, $C{LON_NY}], 'New York coords correct');
};

subtest '_fetch_coordinates: second known address returns correct lat/lon pair' => sub {
	my @got = $osm->_fetch_coordinates('San Francisco, CA');
	is_deeply(\@got, [$C{LAT_SF}, $C{LON_SF}], 'San Francisco coords correct');
};

subtest '_fetch_coordinates: unknown address returns (undef, undef)' => sub {
	my ($lat, $lon) = $osm->_fetch_coordinates('Unknown Place');
	is($lat, undef, 'lat is undef for unknown place');
	is($lon, undef, 'lon is undef for unknown place');
};

subtest 'add_marker: geocoded address stores correct coordinates' => sub {
	my $m = HTML::OSM->new(geocoder => $geocoder);
	ok($m->add_marker(['New York, NY'], html => 'NY Marker'),
		'add_marker returns 1 for geocoded address');
	is_deeply($m->{coordinates}[0], [$C{LAT_NY}, $C{LON_NY}, 'NY Marker', undef],
		'marker tuple stored with geocoded coordinates');
};

subtest 'add_marker: unknown address returns 0 and stores nothing' => sub {
	my $m = HTML::OSM->new(geocoder => $geocoder);
	ok(!$m->add_marker(['Unknown Place'], html => 'Bad Marker'),
		'add_marker returns 0 for unknown location');
	is(scalar @{$m->{coordinates}}, 0, 'no marker stored after failed geocode');
};

restore_all();
done_testing();
