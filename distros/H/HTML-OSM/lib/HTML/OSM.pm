#!/usr/bin/env perl

package HTML::OSM;

use strict;
use warnings;

use Carp;
use CHI;
use File::Slurp;
use LWP::UserAgent;
use JSON::MaybeXS;
use Scalar::Util;
use Time::HiRes;

=head1 NAME

HTML::OSM - A module to generate an interactive OpenStreetMap with customizable coordinates and zoom level.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

C<HTML::OSM> is a Perl module for generating an interactive map using OpenStreetMap (OSM) and Leaflet.
The module accepts a list of coordinates with optional labels and zoom level to create a dynamic HTML file containing an interactive map.
The generated map allows users to view marked locations, zoom, and search for locations using the Nominatim API.

    use HTML::OSM;
    my $map = HTML::OSM->new();
    # ...

    $map = HTML::OSM->new(
	coordinates => [
	  [34.0522, -118.2437, 'Los Angeles'],
	  [undef, undef, 'Paris'],
	],
	zoom => 14,
    );
    my ($head, $map_div) = $map->onload_render();

=over 4

=item * Caching

Identical geocode requests are cached (using L<CHI> or a user-supplied caching object),
reducing the number of HTTP requests to the API and speeding up repeated queries.

This module leverages L<CHI> for caching geocoding responses.
When a geocode request is made,
a cache key is constructed from the request.
If a cached response exists,
it is returned immediately,
avoiding unnecessary API calls.

=item * Rate-Limiting

A minimum interval between successive API calls can be enforced to ensure that the API is not overwhelmed and to comply with any request throttling requirements.

Rate-limiting is implemented using L<Time::HiRes>.
A minimum interval between API
calls can be specified via the C<min_interval> parameter in the constructor.
Before making an API call,
the module checks how much time has elapsed since the
last request and,
if necessary,
sleeps for the remaining time.

=back

=head1 SUBROUTINES/METHODS

=head2 new

    $map = HTML::OSM->new(
	coordinates => [
	  [37.7749, -122.4194, 'San Francisco'],
	  [40.7128, -74.0060, 'New York'],
	  [51.5074, -0.1278, 'London'],
	],
	zoom => 10,
    );

Creates a new C<HTML::OSM> object with the provided coordinates and optional zoom level.

=over 4

=item * C<cache>

A caching object.
If not provided,
an in-memory cache is created with a default expiration of one hour.

=item * coordinates

An array reference containing a list of coordinates.
Each entry should be an array with latitude, longitude, and an optional label, in the format:

  [latitude, longitude, label, icon_url]

If latitude and/or longitude is undefined,
the label is taken to be a location to be added.
If no coordinates are provided, an error will be thrown.

=item * C<geocoder>

An optional geocoder object such as L<Geo::Coder::List> or L<Geo::Coder::Free>.

=item * C<height>

Height (in pixels or using your own unit), the default is 400px.

=item * C<min_interval>

Minimum number of seconds to wait between API requests.
Defaults to C<0> (no delay).
Use this option to enforce rate-limiting.

=item * C<ua>

An object to use for HTTP requests.
If not provided, a default user agent is created.

=item * C<host>

The API host endpoint.
Defaults to L<https://nominatim.openstreetmap.org/search>.

=item * C<width>

Width (in pixels or using your own unit), the default is 600px.

=item * zoom

An optional zoom level for the map, with a default value of 17.

=back

=cut

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my %args;
	if((@_ == 1) && (ref $_[0] eq 'HASH')) {
		# If the first argument is a hash reference, dereference it
		%args = %{$_[0]};
	} elsif((scalar(@_) % 2) == 0) {
		# If there is an even number of arguments, treat them as key-value pairs
		%args = @_;
	} else {
		# If there is an odd number of arguments, treat it as an error
		Carp::carp(__PACKAGE__, ': Invalid arguments passed to new()');
		return;
	}

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			# Using HTML::OSM:new(), not HTML::OSM->new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %args }, ref($class);
	}

	if($args{'coordinates'} && !ref($args{'coordinates'})) {
		Carp::croak(__PACKAGE__, ': coordinates must be a reference to an array');
	}

	# Set up caching (default to an in-memory cache if none provided)
	my $cache = $args{cache} || CHI->new(
		driver => 'Memory',
		global => 1,
		expires_in => '1 day',
	);

	# Set up rate-limiting: minimum interval between requests (in seconds)
	my $min_interval = $args{min_interval} || 0;	# default: no delay

	return bless {
		cache => $cache,
		coordinates => $args{coordinates} || [],
		height => $args{'height'} || '400px',
		host => $args{'host'} || 'nominatim.openstreetmap.org/search',
		width => $args{'width'} || '600px',
		zoom => $args{zoom} || 17,
		min_interval => $min_interval,
		last_request => 0,	# Initialize last_request timestamp
		%args
	}, $class;
}

=head2 add_marker

Add a marker to the map at the given point.
A point can be a unique place name, like an address,
an object that understands C<latitude()> and C<longitude()>,
or a pair of coordinates passed in as an arrayref: C<[ longitude, latitude ]>.
Will return 0 if the point is not found and 1 on success.

It takes two optional arguments:

=over 4

=item * html

Add a popup info window as well.

=item * icon

A url to the icon to be added.

=back

=cut

sub add_marker
{
	my $self = shift;
	my $params;
	my $point;

	if(ref($_[0]) eq 'ARRAY') {
		$point = shift;
		$params = $self->_get_params(undef, @_);
		if(scalar(@{$point}) == 1) {
			$point = @{$point}[0];
		}
	} else {
		$params = $self->_get_params('point', @_);
		$point = $params->{'point'};
	}

	my ($lat, $lon);

	if(ref($params)) {
		if(ref($point) eq 'ARRAY') {
			if(scalar(@{$point}) == 2) {
				($lat, $lon) = @{$point};
			} else {
				return 0;
			}
		} elsif($point->can('latitude')) {
			$lat = $point->latitude();
			$lon = $point->longitude();
		} elsif(!ref($point)) {
			($lat, $lon) = $self->_fetch_coordinates($point);
		} else {
			die 'add_marker(): what is the type of point?'
		}
		return 0 unless(defined($lat) && defined($lon));
		return 0 if(!_validate($lat, $lon));
	} else {
		($lat, $lon) = $self->_fetch_coordinates($point);
		return 0 unless(defined($lat) && defined($lon));
	}

	push @{$self->{coordinates}}, [$lat, $lon, $params->{'html'}, $params->{'icon'}];

	return 1;
}

=head2 center

Center the map at a given point. Returns 1 on success, 0 if the point could not be found.

=cut

sub center
{
	my $self = shift;
	my $params = $self->_get_params('point', @_);
	my $point = $params->{'point'};

	my ($lat, $lon);

	if(ref($params)) {
		if(ref($point) eq 'ARRAY') {
			if(scalar(@{$point}) == 2) {
				($lat, $lon) = @{$point};
			} else {
				die 'add_marker(): point should have both latitude and longitude';
			}
		} elsif($point->can('latitude')) {
			$lat = $point->latitude();
			$lon = $point->longitude();
		} elsif(!ref($point)) {
			($lat, $lon) = $self->_fetch_coordinates($point);
		} else {
			die 'add_marker(): what is the type of point?'
		}
		return 0 if(!_validate($lat, $lon));
	} else {
		($lat, $lon) = $self->_fetch_coordinates($point);
	}
	return 0 unless(defined($lat) && defined($lon));

	$self->{'center'} = [$lat, $lon];

	return 1;
}

=head2 zoom

Get/set the new zoom level (0 is corsest)

    $map->zoom(10);

=cut

sub zoom
{
	my $self = shift;

	if(scalar(@_)) {
		my $params = $self->_get_params('zoom', @_);

		Carp::croak(__PACKAGE__, 'invalid zoom') if($params->{'zoom'} =~ /\D/);
		Carp::croak(__PACKAGE__, 'zoom must be positive') if($params->{'zoom'} < 0);

		$self->{'zoom'} = $params->{'zoom'};
	}

	return $self->{'zoom'};
}

sub _fetch_coordinates
{
	my ($self, $location) = @_;

	die 'address not given to _fetch_coordinates' unless($location);

	if(my $geocoder = $self->{'geocoder'}) {
		if(my $rc = $geocoder->geocode($location)) {
			if(Scalar::Util::blessed($rc) && $rc->can('latitude')) {
				return ($rc->latitude(), $rc->longitude());
			}
			if(ref($rc) eq 'HASH') {
				if(defined($rc->{'lat'}) && defined($rc->{'lon'})) {
					return ($rc->{'lat'}, $rc->{'lon'});
				}
				if(defined($rc->{'geometry'}{'location'}{'lat'})) {
					return ($rc->{'geometry'}{'location'}{'lat'}, $rc->{'geometry'}{'location'}{'lng'});
				}
			}
			if(ref($rc) eq 'ARRAY') {
				return $rc;
			}
			print ref($rc), "\n";
		}
		return;
	}
	my $ua = $self->{'ua'} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	$ua->default_header(accept_encoding => 'gzip,deflate');
	$ua->env_proxy(1);
	$location =~ s/\s/%20/g;
	my $url = 'https://' . $self->{'host'} . "?format=json&q=$location";

	# Create a cache key based on the location (might want to use a stronger hash function if needed)
	my $cache_key = "osm:$location";
	if(my $cached = $self->{cache}->get($cache_key)) {
		return ($cached->{lat}, $cached->{lon});
	}

	# Enforce rate-limiting: ensure at least min_interval seconds between requests.
	my $now = time();
	my $elapsed = $now - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}

	my $response = $ua->get($url);

	# Update last_request timestamp
	$self->{'last_request'} = time();

	if($response->is_success()) {
		if(my $data = decode_json($response->decoded_content())) {
			if(ref($data) eq 'ARRAY') {
				$data = @{$data}[0];
			}
			if(ref($data) eq 'HASH') {
				# Cache the result before returning it
				$self->{'cache'}->set($cache_key, $data);

				return ($data->{lat}, $data->{lon});
			}
		}
	}
	# Carp::croak("Error fetching coordinates for: $location");
	return
}

=head2 onload_render

Renders the map and returns a two element list.
The first element needs to be placed in the head section of your HTML document.
The second in the body where you want the map to appear.

=cut

sub onload_render
{
	my $self = shift;

	# Default size if not provided
	my $height = $self->{'height'} || '500px';
	my $width = $self->{'width'} || '100%';

	my $coordinates = $self->{coordinates};

	die 'No coordinates provided' unless @$coordinates;

	my @valid_coordinates;

	foreach my $coord (@$coordinates) {
		my ($lat, $lon, $label, $icon_url) = @$coord;

		# If an address is provided instead of coordinates, fetch dynamically
		if (!defined $lat || !defined $lon) {
			($lat, $lon) = $self->_fetch_coordinates($label);
		} else {
			next if(!_validate($lat, $lon));
		}

		push @valid_coordinates, [$lat, $lon, $label, $icon_url];
	}

	# Ensure at least one valid coordinate exists
	die 'Error: No valid coordinates provided' unless @valid_coordinates;

	my ($min_lat, $min_lon, $max_lat, $max_lon) = (90, 180, -90, -180);

	foreach my $coord (@valid_coordinates) {
		my ($lat, $lon, $label) = @$coord;
		$min_lat = $lat if $lat < $min_lat;
		$max_lat = $lat if $lat > $max_lat;
		$min_lon = $lon if $lon < $min_lon;
		$max_lon = $lon if $lon > $max_lon;
	}

	my $center_lat = ($min_lat + $max_lat) / 2;
	my $center_lon = ($min_lon + $max_lon) / 2;

	my $head = qq{
		<head>
			<title>Interactive Map</title>
			<link rel="stylesheet" href="https://unpkg.com/leaflet\@1.7.1/dist/leaflet.css" />
			<script src="https://unpkg.com/leaflet\@1.7.1/dist/leaflet.js"></script>
			<style>
				#map { width: $width; height: $height; }
				#search-box { margin: 10px; padding: 5px; }
				#reset-button { margin: 10px; padding: 5px; cursor: pointer; }
			</style>
		</head>
	};

	my $body = qq{
		<!--
			<input type="text" id="search-box" placeholder="Enter location">
			<button id="reset-button">Reset Map</button>
		-->
		<div id="map"></div>
		<script>
			var map = L.map('map').setView([$center_lat, $center_lon], $self->{zoom});
			L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
				attribution: '&copy; OpenStreetMap contributors'
			}).addTo(map);

			var markers = [];
	};

	my @js_markers;
	foreach my $coord (@valid_coordinates) {
		my ($lat, $lon, $label, $icon_url) = @$coord;
		$label =~ s/'/\\'/g;	# Escape single quotes

		# $icon_url ||= 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png';
		if ($icon_url) {
			my $icon_js = qq{
				const customIcon = L.icon({
					iconUrl: '$icon_url',
					// iconSize: [32, 32],
					iconAnchor: [16, 32],
					popupAnchor: [0, -32]
				});
			};

			push @js_markers, qq{
				$icon_js
				var marker = L.marker([$lat, $lon], { icon: customIcon }).addTo(map).bindPopup('$label');
				markers.push(marker);
			};
		} else {
			push @js_markers, "var marker = L.marker([$lat, $lon]).addTo(map).bindPopup('$label'); markers.push(marker);";
		}
	}

	$body .= join("\n", @js_markers);

	$body .= qq{
		document.getElementById('reset-button').addEventListener('click', function() {
			map.setView([$center_lat, $center_lon], $self->{zoom});
		});

		document.getElementById('search-box').addEventListener('keyup', function(event) {
			if (event.key === 'Enter') {
				var query = event.target.value.trim();
				if (!query) {
					alert('Please enter a valid location.');
					return;
				}

				fetch(`https://nominatim.openstreetmap.org/search?format=json&q=\${query}`, {
					headers: { 'User-Agent': '__PACKAGE__' }
				})
				.then(response => response.json())
				.then(data => {
					if (data.length > 0) {
						var lat = data[0].lat;
						var lon = data[0].lon;
						map.setView([lat, lon], 14);
						var searchMarker = L.marker([lat, lon]).addTo(map).bindPopup(query).openPopup();
						markers.push(searchMarker);
					} else {
						alert('No results found. Try a different location.');
					}
				})
				.catch(error => {
					console.error('Error fetching location:', error);
					alert('Failed to fetch location. Please check your internet connection and try again.');
				});
			}
		});

		</script>
	};

	return ($head, $body);
}

sub _validate
{
	my($lat, $lon) = @_;

	# Validate Latitude and Longitude
	if(!defined $lat || !defined $lon || $lat !~ /^-?\d*(\.\d+)?$/ || $lon !~ /^-?\d*(\.\d+)?$/) {
		Carp::carp("Skipping invalid coordinate: ($lat, $lon)") if(defined($lat) && defined($lon));
		return 0;
	}
	if ($lat < -90 || $lat > 90 || $lon < -180 || $lon > 180) {
		Carp::carp("Skipping out-of-range coordinate: ($lat, $lon)");
		return 0;
	}
	return 1;
}

# Helper routine to parse the arguments given to a function.
# Processes arguments passed to methods and ensures they are in a usable format,
#	allowing the caller to call the function in anyway that they want
#	e.g. foo('bar'), foo(arg => 'bar'), foo({ arg => 'bar' }) all mean the same
#	when called _get_params('arg', @_);
sub _get_params
{
	shift;  # Discard the first argument (typically $self)
	my $default = shift;

	# Directly return hash reference if the first parameter is a hash reference
	return $_[0] if(ref($_[0]) eq 'HASH');

	my %rc;
	my $num_args = scalar @_;

	# Populate %rc based on the number and type of arguments
	if(($num_args == 1) && (defined $default)) {
		# %rc = ($default => shift);
		return { $default => shift };
	} elsif($num_args == 1) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	} elsif(($num_args == 0) && (defined($default))) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], "($default => \$val)");
	} elsif(($num_args % 2) == 0) {
		%rc = @_;
	} elsif($num_args == 0) {
		return;
	} else {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	}

	return \%rc;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

=head1 SEE ALSO

=over 4

=item * L<https://wiki.openstreetmap.org/wiki/API>

=item * L<File::Slurp>

=item * C<HTML::GoogleMaps::V3>

Much of the interface to C<HTML::OSM> mimicks this for compatability.

=item * L<Leaflet>

=back

You can find documentation for this module with the perldoc command.

    perldoc HTML::OSM

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/HTML-OSM>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-OSM>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=HTML-OSM>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=HTML::OSM>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-html-osm at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-OSM>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head2 TODO

Allow dynamic addition/removal of markers via user input.

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

__END__
