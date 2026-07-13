#!/usr/bin/env perl

package HTML::OSM;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(carp croak);
use CHI;
use JSON::MaybeXS qw(decode_json encode_json);
use LWP::UserAgent;
use Object::Configure 0.15;
use Params::Get 0.13;
use Params::Validate::Strict 0.28;
use Readonly;
use Scalar::Util qw(blessed);
use Time::HiRes qw(time);
use URI::Escape qw(uri_escape_utf8);

=head1 NAME

HTML::OSM - Generate an interactive OpenStreetMap with Leaflet.js

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

# CDN URLs pinned to tested versions.  Override via constructor params to use
# a self-hosted copy or a different version.
Readonly::Scalar my $LEAFLET_CSS_URL         => 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
Readonly::Scalar my $LEAFLET_JS_URL          => 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
Readonly::Scalar my $CLUSTER_JS_URL          => 'https://unpkg.com/leaflet.markercluster@1.5.3/dist/leaflet.markercluster.js';
Readonly::Scalar my $CLUSTER_CSS_URL         => 'https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.css';
Readonly::Scalar my $CLUSTER_DEFAULT_CSS_URL => 'https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.Default.css';
Readonly::Scalar my $HEATMAP_JS_URL          => 'https://unpkg.com/leaflet.heat@0.2.0/dist/leaflet-heat.js';
Readonly::Scalar my $GPX_JS_URL              => 'https://cdnjs.cloudflare.com/ajax/libs/leaflet-gpx/1.7.0/gpx.min.js';
Readonly::Scalar my $NOMINATIM_HOST          => 'nominatim.openstreetmap.org/search';

# WGS-84 valid ranges
Readonly::Scalar my $LAT_MIN => -90;
Readonly::Scalar my $LAT_MAX =>  90;
Readonly::Scalar my $LON_MIN => -180;
Readonly::Scalar my $LON_MAX =>  180;
Readonly::Scalar my $ZOOM_MIN =>  0;
Readonly::Scalar my $ZOOM_MAX => 19;

=head1 SYNOPSIS

    use HTML::OSM;

    my $map = HTML::OSM->new(
        coordinates => [
            [37.7749, -122.4194, 'San Francisco'],
            [undef,   undef,     'Paris'],
        ],
        zoom => 10,
    );
    my ($head, $body) = $map->onload_render();

=over 4

=item * Caching

Geocode results are cached via L<CHI> (default: in-memory, 1-day TTL).
Supply your own C<cache> object to persist across processes.

=item * Rate-Limiting

Set C<min_interval> (seconds) to throttle outbound Nominatim calls
and comply with the API fair-use policy.

=back

=head1 SUBROUTINES/METHODS

=head2 new

Construct a new C<HTML::OSM> object.

    my $map = HTML::OSM->new(%params);
    my $map = HTML::OSM->new(\%params);

Both method-style (C<< HTML::OSM->new(...) >>) and function-style
(C<HTML::OSM::new(...)>) calls are supported.
Calling C<< $existing_obj->new(%overrides) >> performs a shallow clone,
merging C<%overrides> onto the existing object's state without re-validating.

=head3 API SPECIFICATION

=head4 INPUT

  {
    cache                   => { type => object, can => [get, set], optional },
    cluster                 => { type => boolean,                   optional },
    cluster_css_url         => { type => string,                    optional },
    cluster_default_css_url => { type => string,                    optional },
    cluster_js_url          => { type => string,                    optional },
    config_file             => { type => string,                    optional },
    coordinates             => { type => arrayref,                  optional },
    css_url                 => { type => string,                    optional },
    geocoder                => { type => object, can => geocode,    optional },
    gpx_js_url              => { type => string,                    optional },
    heatmap_js_url          => { type => string,                    optional },
    height                  => { type => string,                    optional },
    host                    => { type => string,                    optional },
    js_url                  => { type => string,                    optional },
    logger                  => { type => object,                    optional },
    min_interval            => { type => number,  min => 0,         optional },
    ua                      => { type => object,                    optional },
    width                   => { type => string,                    optional },
    zoom                    => { type => integer, min => 0, max => 19, optional },
  }

=head4 OUTPUT

  { type => object, isa => 'HTML::OSM' }

=head3 MESSAGES

  | Message                                        | Meaning / Resolution                          |
  |------------------------------------------------|-----------------------------------------------|
  | (validation error from Params::Validate::Strict) | A param has the wrong type or is out of range |

=head3 PSEUDOCODE

  1. If $class is neither a package name nor a blessed ref, treat as
     function-style call: prepend $class back onto @_ and use __PACKAGE__.
  2. If $class is a blessed ref (clone call): merge override params onto a
     shallow copy and return immediately, bypassing schema validation.
  3. Validate all supplied args against the declared schema.
  4. Merge config-file settings via Object::Configure.
  5. Resolve the cache: caller-supplied object, or in-memory CHI instance.
  6. Bless and return with Readonly CDN constants as defaults.

=cut

sub new
{
	my $class = shift;

	# Function-style call: HTML::OSM::new(key => val).
	# Perl places the first argument where the class name should be,
	# so we put it back and set the class explicitly.
	if(defined($class) && !blessed($class) && !UNIVERSAL::isa($class, __PACKAGE__)) {
		unshift @_, $class;
		$class = __PACKAGE__;
	}

	# Clone path: $obj->new(%overrides) — shallow-merge onto the existing
	# object without re-running schema validation so subclasses can extend.
	if(blessed($class)) {
		my $extra = Params::Get::get_params(undef, \@_) || {};
		return bless { %{$class}, %{$extra} }, ref($class);
	}

	$class //= __PACKAGE__;

	my $params = Params::Validate::Strict::validate_strict({
		args   => Params::Get::get_params(undef, \@_) || {},
		schema => {
			cache                   => { type => 'object',  can => [qw(get set)], optional => 1 },
			cluster                 => { type => 'boolean',                        optional => 1 },
			cluster_css_url         => { type => 'string',                         optional => 1 },
			cluster_default_css_url => { type => 'string',                         optional => 1 },
			cluster_js_url          => { type => 'string',                         optional => 1 },
			config_file             => { type => 'string',                         optional => 1 },
			coordinates             => { type => 'arrayref',                       optional => 1 },
			css_url                 => { type => 'string',                         optional => 1 },
			geocoder                => { type => 'object',  can => 'geocode',      optional => 1 },
			gpx_js_url              => { type => 'string',                         optional => 1 },
			heatmap_js_url          => { type => 'string',                         optional => 1 },
			height                  => { type => 'string',                         optional => 1 },
			host                    => { type => 'string',                         optional => 1 },
			js_url                  => { type => 'string',                         optional => 1 },
			logger                  => { type => 'object',                         optional => 1 },
			min_interval            => { type => 'number',  min => 0,              optional => 1 },
			ua                      => { type => 'object',                         optional => 1 },
			width                   => { type => 'string',                         optional => 1 },
			zoom                    => { type => 'integer', min => $ZOOM_MIN, max => $ZOOM_MAX, optional => 1 },
		},
	});

	# Config file values override programmatic defaults (separation of config and code).
	$params = Object::Configure::configure($class, $params);

	# Inject the resolved cache so the bless hash spreads it correctly.
	$params->{cache} //= CHI->new(
		driver     => 'Memory',
		global     => 1,
		expires_in => '1 day',
	);

	return bless {
		# Defaults — spread of %{$params} below overrides each one when supplied.
		coordinates             => [],
		height                  => '400px',
		host                    => $NOMINATIM_HOST,
		width                   => '600px',
		zoom                    => 12,
		min_interval            => 0,
		last_request            => 0,
		cluster                 => 0,
		css_url                 => $LEAFLET_CSS_URL,
		js_url                  => $LEAFLET_JS_URL,
		cluster_js_url          => $CLUSTER_JS_URL,
		cluster_css_url         => $CLUSTER_CSS_URL,
		cluster_default_css_url => $CLUSTER_DEFAULT_CSS_URL,
		heatmap_js_url          => $HEATMAP_JS_URL,
		gpx_js_url              => $GPX_JS_URL,
		%{$params},
	}, $class;
}

=head2 add_marker

Add a point marker to the map.

    $map->add_marker([51.5074, -0.1278], html => 'London');
    $map->add_marker('Paris, France',    html => 'Paris');
    $map->add_marker($geo_coder_result);

Returns 1 on success, 0 if the point cannot be resolved or is out of range.

=head3 API SPECIFICATION

=head4 INPUT

  point : arrayref [lat, lon] | string address | object with latitude()/longitude()
  html  : string   (optional popup label)
  icon  : string   (optional icon URL)

=head4 OUTPUT

  { type => integer, enum => [0, 1] }

=head3 MESSAGES

  | Message                              | Meaning / Resolution                        |
  |--------------------------------------|---------------------------------------------|
  | add_marker(): unknown point type     | Point is a ref type with no lat/lon methods |

=head3 EXAMPLES

    # Coordinate array with a popup label
    $map->add_marker([51.5074, -0.1278], html => 'London');

    # String address geocoded via the injected geocoder or Nominatim
    $map->add_marker('Paris, France', html => 'Paris');

    # Custom icon URL with a popup
    $map->add_marker(
        [40.7128, -74.0060],
        html => 'New York',
        icon => 'https://example.com/pin.png',
    );

    # Geo::Coder result object that implements latitude()/longitude()
    my $result = $geocoder->geocode('Berlin, Germany');
    $map->add_marker($result, html => 'Berlin');

    # Accumulate several markers, warn on geocode failure
    for my $city (@cities) {
        $map->add_marker($city->{coords}, html => $city->{name})
            or warn "Could not place $city->{name}";
    }

=cut

sub add_marker
{
	my $self = shift;
	my ($params, $point);

	if(ref($_[0]) eq 'ARRAY') {
		$point  = shift;
		$params = Params::Get::get_params(undef, \@_) || {};
		# Single-element arrayref is a wrapped address string
		$point  = $point->[0] if scalar(@{$point}) == 1;
	} elsif(blessed($_[0]) && $_[0]->can('latitude')) {
		# Geo object as first positional arg: extract before Params::Get sees it,
		# otherwise Params::Get mistakes the blessed hashref for the params hash.
		$point  = shift;
		$params = Params::Get::get_params(undef, \@_) || {};
	} elsif(defined($_[0]) && !ref($_[0]) && scalar(@_) % 2 != 0) {
		# Plain string as first positional arg, optionally followed by key-value pairs.
		# An odd total count signals a leading positional; even count means all key-value.
		$point  = shift;
		$params = Params::Get::get_params(undef, \@_) || {};
	} else {
		$params = Params::Get::get_params('point', @_);
		$point  = $params->{'point'};
	}

	my ($lat, $lon);

	if(ref($point) eq 'ARRAY') {
		return 0 if scalar(@{$point}) != 2;
		($lat, $lon) = @{$point};
	} elsif(!ref($point)) {
		($lat, $lon) = $self->_fetch_coordinates($point);
	} elsif($point->can('latitude')) {
		($lat, $lon) = ($point->latitude(), $point->longitude());
	} else {
		my $msg = 'add_marker(): unknown point type: ' . ref($point);
		$self->{logger}->error($msg) if $self->{logger};
		croak $msg;
	}

	return 0 unless defined($lat) && defined($lon);
	return 0 unless _validate($lat, $lon);

	push @{$self->{coordinates}}, [$lat, $lon, $params->{'html'}, $params->{'icon'}];
	return 1;
}

=head2 add_geojson

Add a GeoJSON layer to the map.

    $map->add_geojson(\%data, style => { color => '#ff0000' }, popup => 'name');

The first argument may be a hashref/arrayref (GeoJSON structure) or a JSON string.
Returns 1 on success.

=head3 API SPECIFICATION

=head4 INPUT

  data  : hashref | arrayref | string (JSON)
  style : hashref   Leaflet path-style options (color, weight, fillColor, fillOpacity)
  popup : string    Feature property name whose value becomes the popup text

=head4 OUTPUT

  { type => integer, value => 1 }

=head3 MESSAGES

  | Message              | Meaning / Resolution            |
  |----------------------|---------------------------------|
  | (JSON parse error)   | data string is not valid JSON   |

=head3 EXAMPLES

    # Pre-parsed GeoJSON structure with style and popup property
    $map->add_geojson(
        { type => 'FeatureCollection', features => \@features },
        style => { color => '#ff0000', weight => 2, fillOpacity => 0.4 },
        popup => 'name',
    );

    # Raw JSON string — decoded automatically
    $map->add_geojson('{"type":"FeatureCollection","features":[]}');

    # Multiple GeoJSON layers with different styles on the same map
    $map->add_geojson(\%country_borders, style => { color => '#333333', fillOpacity => 0 });
    $map->add_geojson(\%river_data,      style => { color => '#0099ff', weight => 1    });

=cut

sub add_geojson
{
	my $self   = shift;
	my $data   = shift;
	my $params = Params::Get::get_params(undef, \@_) || {};

	# Accept either a pre-parsed structure or a raw JSON string
	$data = decode_json($data) if !ref($data);

	push @{$self->{geojson}}, { data => $data, opts => $params };
	return 1;
}

=head2 add_heatmap

Add a heatmap layer to the map.

    $map->add_heatmap([[51.5, -0.1, 0.8], [51.6, -0.2, 0.5]], radius => 25);

Each point is C<[$lat, $lon]> or C<[$lat, $lon, $intensity]> (intensity: 0-1).
Requires the Leaflet.heat plugin (C<heatmap_js_url>).
Returns 1 on success.

=head3 API SPECIFICATION

=head4 INPUT

  points : arrayref of ([lat, lon] | [lat, lon, intensity])
  radius : integer  default 25
  blur   : integer  default 15

=head4 OUTPUT

  { type => integer, value => 1 }

=head3 MESSAGES

  | Message                              | Meaning / Resolution              |
  |--------------------------------------|-----------------------------------|
  | add_heatmap: points must be arrayref | First argument is not an arrayref |

=head3 EXAMPLES

    # Basic heatmap — [lat, lon] per point
    $map->add_heatmap([
        [51.5074, -0.1278],
        [51.6000, -0.2000],
        [51.4000,  0.0000],
    ]);

    # With intensity values (0..1) and custom radius/blur
    $map->add_heatmap(
        [ [51.5, -0.1, 0.9], [51.6, -0.2, 0.5], [51.4, 0.0, 0.2] ],
        radius => 30,
        blur   => 20,
    );

=cut

sub add_heatmap
{
	my $self   = shift;
	my $points = shift;
	my $params = Params::Get::get_params(undef, \@_) || {};

	croak 'add_heatmap: points must be an arrayref' unless ref($points) eq 'ARRAY';

	push @{$self->{heatmap_layers}}, { points => $points, opts => $params };
	return 1;
}

=head2 add_gpx

Add a GPX track to the map from a URL.

    $map->add_gpx('https://example.com/track.gpx');

The map view is auto-fitted to the track bounds after loading.
Requires the leaflet-gpx plugin (C<gpx_js_url>).
Returns 1 on success.

=head3 API SPECIFICATION

=head4 INPUT

  url : string  URL of the GPX file (required)

=head4 OUTPUT

  { type => integer, value => 1 }

=head3 MESSAGES

  | Message              | Meaning / Resolution       |
  |----------------------|----------------------------|
  | add_gpx: url required | No URL argument supplied  |

=head3 EXAMPLES

    # Add a GPX track from a public URL; the map auto-fits to its bounds
    $map->add_gpx('https://example.com/route.gpx');

    # Multiple tracks on the same map
    $map->add_gpx('https://example.com/morning-run.gpx');
    $map->add_gpx('https://example.com/evening-walk.gpx');

=cut

sub add_gpx
{
	my $self   = shift;
	my $params = Params::Get::get_params('url', \@_);
	my $url    = $params->{'url'};

	croak 'add_gpx: url is required' unless $url;

	push @{$self->{gpx_tracks}}, $url;
	return 1;
}

=head2 add_choropleth

Add a choropleth (data-driven colour fill) layer to the map.

    $map->add_choropleth(
        \@geojson_features,
        { England => 100, Scotland => 80, Wales => 60 },
        key   => 'name',
        scale => ['#ffffcc', '#a1dab4', '#41b6c4', '#2c7fb8', '#253494'],
    );

Colours are pre-computed in Perl and baked into the emitted JavaScript.
No extra browser plugin is required.
Returns 1 on success.

=head3 API SPECIFICATION

=head4 INPUT

  features : arrayref of GeoJSON Feature hashrefs  (required)
  values   : hashref  { feature_property_value => numeric_value }  (required)
  key      : string   feature property to match against values  (default: 'name')
  scale    : arrayref hex-colour strings low-to-high  (default: 5-step YlGnBu)

=head4 OUTPUT

  { type => integer, value => 1 }

=head3 MESSAGES

  | Message                                  | Meaning / Resolution                   |
  |------------------------------------------|----------------------------------------|
  | add_choropleth: features must be arrayref | First argument is not an arrayref      |
  | add_choropleth: values must be hashref    | Second argument is not a hashref       |

=head3 EXAMPLES

    # Default 5-step YlGnBu scale, key property "name"
    $map->add_choropleth(
        \@geojson_features,
        { England => 100, Scotland => 80, Wales => 60 },
    );

    # Custom 3-step scale and a different GeoJSON property as the key
    $map->add_choropleth(
        \@geojson_features,
        { England => 100, Scotland => 80, Wales => 60 },
        key   => 'country',
        scale => ['#f7fbff', '#6baed6', '#08519c'],
    );

    # choropleth-only map — center() must be called explicitly
    $map->center([54.0, -2.0]);
    $map->add_choropleth(\@uk_features, \%population_by_region);
    my ($head, $body) = $map->onload_render();

=cut

sub add_choropleth
{
	my $self     = shift;
	my $features = shift;
	my $values   = shift;
	my $params   = Params::Get::get_params(undef, \@_) || {};

	croak 'add_choropleth: features must be an arrayref' unless ref($features) eq 'ARRAY';
	croak 'add_choropleth: values must be a hashref'     unless ref($values)   eq 'HASH';

	my $key   = $params->{key}   || 'name';
	my $scale = $params->{scale} || ['#ffffcc', '#a1dab4', '#41b6c4', '#2c7fb8', '#253494'];

	# Compute colour index for each feature in Perl so the browser needs no
	# extra maths — the resulting lookup object is baked into the JS.
	my @sorted_vals = sort { $a <=> $b } values %{$values};
	my ($min, $max) = ($sorted_vals[0] // 0, $sorted_vals[-1] // 0);
	$max = $min + 1 if $max == $min;    # avoid division by zero for single-value sets

	my %colors;
	while(my ($k, $v) = each %{$values}) {
		my $idx = int(($v - $min) / ($max - $min) * $#{$scale});
		$idx = $#{$scale} if $idx > $#{$scale};
		$colors{$k} = $scale->[$idx];
	}

	push @{$self->{choropleth_layers}}, {
		features => $features,
		values   => $values,
		colors   => \%colors,
		key      => $key,
	};
	return 1;
}

=head2 center

Set the map centre to a given point.

    $map->center([40.7128, -74.0060]);
    $map->center($geo_object);
    $map->center('Berlin, Germany');

Returns 1 on success, 0 if the point cannot be resolved.

=head3 API SPECIFICATION

=head4 INPUT

  point : arrayref [lat, lon] | object with latitude()/longitude() | string address

=head4 OUTPUT

  { type => integer, enum => [0, 1] }

=head3 MESSAGES

  | Message                                        | Meaning / Resolution                     |
  |------------------------------------------------|------------------------------------------|
  | center(): usage: point => [lat, lon]           | No point argument supplied               |
  | center(): point must have latitude & longitude | Arrayref has != 2 elements               |
  | center(): unknown point type                   | Ref type has no lat/lon methods          |

=head3 EXAMPLES

    # Coordinate array
    $map->center([40.7128, -74.0060]);

    # Object that implements latitude()/longitude() (e.g. a Geo::Coder result)
    $map->center($geocoder->geocode('Berlin, Germany'));

    # String address resolved via the injected geocoder or Nominatim
    $map->center('Eiffel Tower, Paris, France');

    # Required when rendering without point markers (GeoJSON-only, choropleth, etc.)
    $map->center([54.0, -2.0]);
    $map->add_geojson(\%uk_regions, popup => 'name');
    my ($head, $body) = $map->onload_render();

=cut

sub center
{
	my $self   = shift;
	my $params = Params::Get::get_params('point', \@_);
	my $point  = $params->{'point'};

	croak 'center(): usage: point => [ latitude, longitude ]' unless defined($point);

	my ($lat, $lon);

	if(ref($point) eq 'ARRAY') {
		croak 'center(): point must have latitude and longitude'
			if scalar(@{$point}) != 2;
		($lat, $lon) = @{$point};
	} elsif(ref($point) && $point->can('latitude')) {
		($lat, $lon) = ($point->latitude(), $point->longitude());
	} elsif(!ref($point)) {
		($lat, $lon) = $self->_fetch_coordinates($point);
	} else {
		my $msg = 'center(): unknown point type: ' . ref($point);
		$self->{logger}->error($msg) if $self->{logger};
		croak $msg;
	}

	return 0 unless defined($lat) && defined($lon);
	return 0 unless _validate($lat, $lon);

	$self->{'center'} = [$lat, $lon];
	return 1;
}

=head2 zoom

Get or set the zoom level (0 = world, 19 = building).

    $map->zoom(10);
    my $z = $map->zoom();

=head3 API SPECIFICATION

=head4 INPUT

  { zoom => { type => integer, min => 0, max => 19, optional => 1 } }

=head4 OUTPUT

  { type => integer, min => 0, max => 19 }

=head3 MESSAGES

  | Message                      | Meaning / Resolution                      |
  |------------------------------|-------------------------------------------|
  | (Params::Validate::Strict)   | zoom is not an integer or is out of range |

=head3 EXAMPLES

    # Setter: store the zoom level
    $map->zoom(14);

    # Getter: retrieve the current level
    my $level = $map->zoom();
    print "Current zoom: $level\n";    # 14

    # Setter return value equals the new level
    my $confirmed = $map->zoom(10);
    die 'unexpected' unless $confirmed == 10;

    # Chain: set via new(), read back via zoom()
    my $m = HTML::OSM->new(zoom => 6);
    $m->zoom($m->zoom() + 2);   # nudge up by 2

=cut

sub zoom
{
	my $self = shift;

	if(scalar(@_)) {
		my $params = Params::Validate::Strict::validate_strict({
			args   => Params::Get::get_params('zoom', \@_),
			schema => {
				zoom => { optional => 1, type => 'integer', min => $ZOOM_MIN, max => $ZOOM_MAX },
			},
		});
		$self->{'zoom'} = $params->{'zoom'} if defined($params->{'zoom'});
	}

	return $self->{'zoom'};
}

=head2 onload_render

Render the map and return a two-element list suitable for embedding in HTML.

    my ($head_html, $body_html) = $map->onload_render();

C<$head_html> contains the Leaflet CSS, JavaScript, and plugin assets.
Place it inside C<< <head>...</head> >>.

C<$body_html> contains the search box, control buttons, map C<< <div> >>,
and the initialisation C<< <script> >>.
Place it inside C<< <body>...</body> >> where the map should appear.

The rendered page provides:

=over 4

=item * A Nominatim-powered search box that adds temporary markers.

=item * A "Clear search markers" button that removes those temporary markers,
leaving static markers (added via C<add_marker>) intact.

=item * A "Reset Map" button that returns the view to the initial centre and zoom.

=back

=head3 API SPECIFICATION

=head4 INPUT

  (none - uses object state)

=head4 OUTPUT

  { type => list, elements => [string, string] }

=head3 MESSAGES

  | Message                                          | Meaning / Resolution                        |
  |--------------------------------------------------|---------------------------------------------|
  | No map data provided                             | No markers, GeoJSON, heatmap, GPX, or choropleth added yet |
  | center() must be called when no point markers    | Non-marker-only render needs explicit centre |

=head3 EXAMPLES

    # Minimal: one marker, embed in a CGI response
    use HTML::OSM;
    my $map = HTML::OSM->new(zoom => 12);
    $map->add_marker([51.5074, -0.1278], html => 'London');
    my ($head, $body) = $map->onload_render();
    print "Content-Type: text/html\n\n";
    print "<html><head>$head</head><body>$body</body></html>\n";

    # Mixed layers: markers + GeoJSON, explicit center
    $map->center([51.5, -0.1]);
    $map->add_geojson(\%borough_data, popup => 'name', style => { color => '#333' });
    $map->add_marker([51.5074, -0.1278], html => 'City of London');
    my ($head_html, $body_html) = $map->onload_render();

    # Template Toolkit integration
    $tt->process('map.tt', {
        map_head => scalar(($map->onload_render())[0]),
        map_body => scalar(($map->onload_render())[1]),
    });

=head3 PSEUDOCODE

  1. Gather all data layers; croak if none populated.
  2. Geocode/validate each coordinate tuple; discard invalids with a warning.
  3. Determine map centre: caller-supplied > computed midpoint of marker bounds.
     Croak if neither is available.
  4. Build <head>: Leaflet CSS + JS; inject cluster/heatmap/GPX plugin assets
     only when the corresponding layer type is present.
  5. Build <body>: search box, clear-search button, reset button, map <div>.
  6. Initialise Leaflet map, tile layer, searchMarkers array.
  7. Emit JS for each marker (via clusterGroup when cluster is set).
  8. Emit JS for each GeoJSON, heatmap, GPX, and choropleth layer.
  9. Attach event listeners: reset-view, clear-search-markers, search-on-Enter.
  10. Return ($head, $body).

=cut

sub onload_render
{
	my $self = shift;

	my $height            = $self->{'height'} || '400px';
	my $width             = $self->{'width'}  || '600px';
	my $coordinates       = $self->{coordinates}        || [];
	my $geojson_layers    = $self->{geojson}             || [];
	my $heatmap_layers    = $self->{heatmap_layers}      || [];
	my $gpx_tracks        = $self->{gpx_tracks}          || [];
	my $choropleth_layers = $self->{choropleth_layers}   || [];

	unless(@$coordinates || @$geojson_layers || @$heatmap_layers
	                     || @$gpx_tracks     || @$choropleth_layers) {
		$self->{logger}->error('No map data provided') if $self->{logger};
		croak 'No map data provided';
	}

	# Geocode address strings; validate and discard bad numeric pairs.
	my @valid_coordinates;
	for my $coord (@$coordinates) {
		my ($lat, $lon, $label, $icon_url) = @$coord;
		if(!defined $lat || !defined $lon) {
			($lat, $lon) = $self->_fetch_coordinates($label);
		}
		# Validate ALL coordinates here — including geocoder-returned ones.
		# A compromised geocoder or Nominatim response could return a crafted
		# lat/lon string that would inject JS if embedded without validation.
		next unless defined($lat) && defined($lon) && _validate($lat, $lon);
		push @valid_coordinates, [$lat, $lon, $label, $icon_url];
	}

	# Determine map centre: caller-set wins; else compute from marker bounds.
	my ($center_lat, $center_lon);
	if($self->{'center'}) {
		($center_lat, $center_lon) = @{$self->{'center'}};
	} elsif(@valid_coordinates) {
		my ($min_lat, $min_lon, $max_lat, $max_lon) = (90, 180, -90, -180);
		for my $c (@valid_coordinates) {
			$min_lat = $c->[0] if $c->[0] < $min_lat;
			$max_lat = $c->[0] if $c->[0] > $max_lat;
			$min_lon = $c->[1] if $c->[1] < $min_lon;
			$max_lon = $c->[1] if $c->[1] > $max_lon;
		}
		$center_lat = ($min_lat + $max_lat) / 2;
		$center_lon = ($min_lon + $max_lon) / 2;
	} else {
		croak 'center() must be called when no point markers are provided';
	}

	# --- <head> ---
	my $head = qq{
		<link rel="stylesheet" href="$self->{css_url}" />
		<script src="$self->{js_url}"></script>
	};

	if($self->{cluster}) {
		$head .= qq{
		<link rel="stylesheet" href="$self->{cluster_css_url}" />
		<link rel="stylesheet" href="$self->{cluster_default_css_url}" />
		<script src="$self->{cluster_js_url}"></script>
		};
	}
	$head .= qq{\t\t<script src="$self->{heatmap_js_url}"></script>\n} if @$heatmap_layers;
	$head .= qq{\t\t<script src="$self->{gpx_js_url}"></script>\n}     if @$gpx_tracks;

	$head .= qq{
		<style>
			#map { width: $width; height: $height; }
			#search-box { margin: 10px; padding: 5px; }
			#reset-button, #clear-search-button { margin: 10px; padding: 5px; cursor: pointer; }
		</style>
	};

	# --- <body> ---
	my $body = qq{
		<input type="text" id="search-box" placeholder="Enter location">
		<button id="clear-search-button">Clear search markers</button>
		<button id="reset-button">Reset Map</button>
		<div id="map"></div>
		<script>
			var map = L.map('map').setView([$center_lat, $center_lon], $self->{zoom});
			L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
				attribution: '&copy; OpenStreetMap contributors'
			}).addTo(map);

			var searchMarkers = [];
	};

	# Point markers — optionally grouped into a cluster layer.
	if(@valid_coordinates) {
		$body .= "\t\t\tvar clusterGroup = L.markerClusterGroup();\n" if $self->{cluster};

		for my $coord (@valid_coordinates) {
			my ($lat, $lon, $label, $icon_url) = @$coord;
			my $js_label = _js_string($label);
			if($icon_url) {
				my $js_icon = _js_string($icon_url);
				my $add_cmd = $self->{cluster}
					? 'clusterGroup.addLayer(m);'
					: 'm.addTo(map);';
				$body .= qq{
			(function() {
				var icon = L.icon({ iconUrl: '$js_icon', iconAnchor: [16,32], popupAnchor: [0,-32] });
				var m = L.marker([$lat, $lon], { icon: icon }).bindPopup('$js_label');
				$add_cmd
			})();
				};
			} elsif($self->{cluster}) {
				$body .= "\t\t\tclusterGroup.addLayer(L.marker([$lat, $lon]).bindPopup('$js_label'));\n";
			} else {
				$body .= "\t\t\tL.marker([$lat, $lon]).addTo(map).bindPopup('$js_label');\n";
			}
		}

		$body .= "\t\t\tmap.addLayer(clusterGroup);\n" if $self->{cluster};
	}

	# GeoJSON layers.
	for my $layer (@$geojson_layers) {
		my $json     = _html_json($layer->{data});
		my $opts     = $layer->{opts} || {};
		my $style_js = '';
		my $popup_js = '';
		if(my $style = $opts->{style}) {
			$style_js = 'style: ' . _html_json($style) . ',';
		}
		if(my $prop = $opts->{popup}) {
			my $js_prop = _js_string($prop);
			$popup_js = "onEachFeature: function(f,l){ if(f.properties && f.properties['$js_prop']){ l.bindPopup(String(f.properties['$js_prop'])); } },";
		}
		$body .= "\t\t\tL.geoJSON($json, { $style_js $popup_js }).addTo(map);\n";
	}

	# Heatmap layers.
	for my $layer (@$heatmap_layers) {
		my $pts    = _html_json($layer->{points});
		my $opts   = $layer->{opts} || {};
		my $radius = $opts->{radius} || 25;
		my $blur   = $opts->{blur}   || 15;
		$body .= "\t\t\tL.heatLayer($pts, { radius: $radius, blur: $blur }).addTo(map);\n";
	}

	# GPX tracks — browser fetches the file; fitBounds called on load.
	for my $url (@$gpx_tracks) {
		my $js_url = _js_string($url);
		$body .= "\t\t\tnew L.GPX('$js_url', { async: true }).on('loaded', function(e){ map.fitBounds(e.target.getBounds()); }).addTo(map);\n";
	}

	# Choropleth layers — colours are pre-baked; no browser-side scale maths.
	for my $layer (@$choropleth_layers) {
		my $fc_json     = _html_json({ type => 'FeatureCollection', features => $layer->{features} });
		my $colors_json = _html_json($layer->{colors});
		my $values_json = _html_json($layer->{values});
		my $js_key      = _js_string($layer->{key});
		$body .= qq{
			(function() {
				var choroplethColors = $colors_json;
				var choroplethValues = $values_json;
				L.geoJSON($fc_json, {
					style: function(f) {
						var k = f.properties && f.properties['$js_key'];
						return { fillColor: choroplethColors[k] || '#cccccc',
						         weight: 2, opacity: 1, color: 'white',
						         dashArray: '3', fillOpacity: 0.7 };
					},
					onEachFeature: function(f, l) {
						var k = f.properties && f.properties['$js_key'];
						if(k && choroplethValues[k] !== undefined) {
							l.bindPopup(k + ': ' + choroplethValues[k]);
						}
					}
				}).addTo(map);
			})();
		};
	}

	# Event handlers.
	$body .= qq{
			document.getElementById('reset-button').addEventListener('click', function() {
				map.setView([$center_lat, $center_lon], $self->{zoom});
			});

			document.getElementById('clear-search-button').addEventListener('click', function() {
				searchMarkers.forEach(function(m) { map.removeLayer(m); });
				searchMarkers = [];
			});

			document.getElementById('search-box').addEventListener('keyup', function(event) {
				if(event.key === 'Enter') {
					var query = event.target.value.trim();
					if(!query) { alert('Please enter a valid location.'); return; }
					fetch('https://nominatim.openstreetmap.org/search?format=json&q=' + encodeURIComponent(query))
					.then(function(r) { return r.json(); })
					.then(function(data) {
						if(data.length > 0) {
							var lat = data[0].lat, lon = data[0].lon;
							map.setView([lat, lon], 14);
							searchMarkers.push(L.marker([lat, lon]).addTo(map).bindPopup(query).openPopup());
						} else {
							alert('No results found. Try a different location.');
						}
					})
					.catch(function(err) {
						console.error('Search error:', err);
						alert('Failed to fetch location. Please check your internet connection.');
					});
				}
			});
		</script>
	};

	return ($head, $body);
}

# _fetch_coordinates: Resolve a place-name string to a (lat, lon) pair.
# Purpose: Centralise all geocoding logic — try the injected geocoder first,
#          fall back to a direct Nominatim HTTP call with caching and rate-limiting.
# Entry:   $self, $location (non-empty string).
# Exit:    ($lat, $lon) strings on success; (undef, undef) on failure.
# Side Effects: May sleep to honour min_interval; writes to $self->{cache}.
sub _fetch_coordinates
{
	my ($self, $location) = @_;

	croak 'address not given to _fetch_coordinates' unless $location;

	# Prefer an injected geocoder (e.g. Geo::Coder::List) to avoid HTTP.
	if(my $geocoder = $self->{'geocoder'}) {
		my $rc = $geocoder->geocode($location);
		return (undef, undef) unless defined $rc;

		if(blessed($rc) && $rc->can('latitude')) {
			return ($rc->latitude(), $rc->longitude());
		}
		if(ref($rc) eq 'HASH') {
			return ($rc->{lat}, $rc->{lon})
				if defined($rc->{lat}) && defined($rc->{lon});
			return ($rc->{geometry}{location}{lat}, $rc->{geometry}{location}{lng})
				if defined($rc->{geometry}{location}{lat});
		}
		# Some geocoders return a flat [lat, lon] arrayref
		return @{$rc} if ref($rc) eq 'ARRAY';

		# Unrecognised return type — treat as failure
		carp '_fetch_coordinates: unrecognised geocoder result type: ' . ref($rc);
		return (undef, undef);
	}

	# Direct Nominatim path: apply caching and rate-limiting.
	my $cache_key = 'osm:' . uri_escape_utf8($location);
	if(my $cached = $self->{cache}->get($cache_key)) {
		return ($cached->{lat}, $cached->{lon});
	}

	# Honour the minimum interval between outbound requests.
	my $elapsed = time() - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}

	my $ua = $self->{'ua'}
		|| LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	$ua->default_header(accept_encoding => 'gzip,deflate');
	$ua->env_proxy(1);

	my $url      = 'https://' . $self->{'host'} . '?format=json&q=' . uri_escape_utf8($location);
	my $response = $ua->get($url);
	$self->{'last_request'} = time();

	if($response->is_success()) {
		# eval guard: Nominatim normally returns valid JSON, but a maintenance
		# page or rate-limit response could return HTML with a 200 OK.  Dying
		# inside _fetch_coordinates would bubble uncaught to add_marker / onload_render.
		my $data = eval { decode_json($response->decoded_content()) };
		if($@) {
			carp "_fetch_coordinates: failed to decode Nominatim response: $@";
			return (undef, undef);
		}
		$data = $data->[0] if ref($data) eq 'ARRAY';
		if(ref($data) eq 'HASH' && defined($data->{lat})) {
			$self->{'cache'}->set($cache_key, $data);
			return ($data->{lat}, $data->{lon});
		}
	}

	return (undef, undef);
}

# _validate: Check that a (lat, lon) pair is numeric and within WGS-84 bounds.
# Purpose: Single guard point for all coordinate ingestion; emits a carp when
#          both values are defined but wrong so the caller can log without dying.
# Entry:   ($lat, $lon) — any scalar, including undef.
# Exit:    1 if valid, 0 if not.
# Side Effects: carp when coordinates are defined but out-of-range/non-numeric.
sub _validate
{
	my ($lat, $lon) = @_;

	# Require at least one digit (rejects empty string — unlike \d* which matches '').
	# Leading-decimal notation (e.g. -.5167) is valid per Changes 0.05.
	# \z (not $) prevents a trailing \n from sneaking through: $ matches before
	# a final newline, which would make "0\n" valid and embed a newline in JS.
	my $numeric = qr/^-?(?:\d+(?:\.\d+)?|\.\d+)\z/;

	my $ok = defined($lat) && defined($lon)
	      && $lat =~ $numeric && $lon =~ $numeric
	      && $lat >= $LAT_MIN && $lat <= $LAT_MAX
	      && $lon >= $LON_MIN && $lon <= $LON_MAX;

	carp(sprintf 'Skipping invalid coordinate: (%s, %s)',
	     $lat // 'undef', $lon // 'undef')
		if !$ok && defined($lat) && defined($lon);

	return $ok ? 1 : 0;
}

# _html_json: Encode data as JSON and make the result safe for embedding in a
# <script> block.  JSON encoders do not escape '/' by default, so a value like
# '</script>' would close the enclosing script tag and allow HTML injection.
# Escaping every '</' as '<\/' prevents this without altering the decoded value.
# Entry:   Any Perl data structure accepted by encode_json.
# Exit:    JSON string safe for direct insertion inside a <script> block.
sub _html_json
{
	my $j = encode_json(shift);
	$j =~ s|</|<\\/|g;
	return $j;
}

# _js_string: Escape a Perl string for safe embedding in a JS single-quoted literal.
# Purpose: Prevent JS injection via user-supplied labels, URLs, or property names.
# Entry:   Any scalar (undef becomes '').
# Exit:    Escaped string safe for insertion between JS single quotes.
sub _js_string
{
	my $s = shift // '';
	$s =~ s/\\/\\\\/g;    # escape backslash first to avoid double-escaping
	$s =~ s/'/\\'/g;      # escape our JS string delimiter
	$s =~ s/\r?\n/\\n/g;  # newlines would break the JS string
	$s =~ s|</|<\\/|g;    # prevent </script> injection
	return $s;
}

=head1 LIMITATIONS

=over 4

=item * B<Per-marker removal>: Markers added via C<add_marker()> cannot yet be
removed individually by clicking them.  The "Clear search markers" button only
removes markers added by the in-page Nominatim search box.

=item * B<Clone validation>: The clone path (C<< $obj->new(%overrides) >>)
bypasses the Params::Validate::Strict schema so subclasses and internal callers
can merge arbitrary state.  Callers are responsible for passing valid overrides.

=item * B<Config-file params unvalidated>: Keys injected by
L<Object::Configure> from a config file are not re-run through the schema, so
a malformed config file can introduce invalid types at runtime.

=item * B<Private-method encapsulation>: C<_fetch_coordinates>, C<_validate>,
and C<_js_string> are named with a leading underscore by convention only.
Using L<Sub::Private> in C<enforce> mode would make the contract explicit, but
that module is not yet listed as a dependency to avoid breaking white-box tests
in C<t/mock.t>.

=item * B<Routing>: Turn-by-turn routing (Leaflet Routing Machine / OSRM) is
explicitly out of scope for this module and will not be added here.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report bugs at L<https://github.com/nigelhorne/HTML-OSM/issues>.

=head1 SEE ALSO

=over 4

=item * L<https://wiki.openstreetmap.org/wiki/API>

=item * L<HTML::GoogleMaps::V3> - the interface this module mirrors for compatibility.

=item * L<https://leafletjs.com/>

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/HTML-OSM/coverage/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-OSM>

=head2 TODO

Allow per-marker removal via clicking on a marker.

=encoding utf-8

=head1 FORMAL SPECIFICATION

=head2 new

  HTML_OSM
    coordinates     : iseq (ℝ x ℝ x S x S)
    zoom            : Z
    cluster         : B
  ----------------------------------------
    ZOOM_MIN <= zoom <= ZOOM_MAX

  new ≙
    params? : Params
    osm!    : HTML_OSM
  ----------------------------------------
    osm!.zoom     = params?.zoom     ∨ 12
    osm!.cluster  = params?.cluster  ∨ false

=head2 add_marker

  AddMarker
    ΔHTML_OSM
    point? : (ℝ x ℝ) ∪ S ∪ GeoObject
    result! : {0, 1}
  -----------------------------------------
    result! = 1 ⟺ point? resolves to (lat, lon) ∈ ValidCoord
    result! = 1 ⟹ coordinates' = coordinates ⌢ ⟨(lat, lon, label, icon)⟩

=head2 add_geojson

  AddGeoJSON
    ΔHTML_OSM
    data?  : GeoJSONStruct ∪ S
    style? : StyleMap ∪ {∅}
    popup? : S ∪ {∅}
  -----------------------------------------
    geojson' = geojson ⌢ ⟨{data, style, popup}⟩

=head2 add_heatmap

  AddHeatmap
    ΔHTML_OSM
    points? : iseq (ℝ x ℝ x [0,1])
  -----------------------------------------
    heatmap_layers' = heatmap_layers ⌢ ⟨{points, radius, blur}⟩

=head2 add_gpx

  AddGPX
    ΔHTML_OSM
    url? : S | url? ≠ ''
  -----------------------------------------
    gpx_tracks' = gpx_tracks ⌢ ⟨url?⟩

=head2 add_chropleth

  AddChoropleth
    ΔHTML_OSM
    features? : iseq GeoFeature
    values?   : S --> ℝ
    key?      : S
    scale?    : iseq S
  -----------------------------------------
    Let min = min(ran values?), max = max(ran values?) ∪ {min+1}
    ∀ k ∈ dom values? •
      color(k) = scale?[floor((values?(k)-min)/(max-min) * (#scale?-1))]
    choropleth_layers' = choropleth_layers ⌢ ⟨{features, values, colors, key}⟩

=head2 center

  Center
    ΔHTML_OSM
    point? : (ℝ x ℝ) ∪ S ∪ GeoObject
    result! : {0, 1}
  -----------------------------------------
    result! = 1 ⟺ point? resolves to (lat, lon) ∈ ValidCoord
    result! = 1 ⟹ center' = (lat, lon)

=head2 zoom

  Zoom
    ΔHTML_OSM
    zoom? : Z ∪ {∅}
    zoom! : Z
  -----------------------------------------
    zoom? ≠ ∅ ⟹ ZOOM_MIN <= zoom? <= ZOOM_MAX
    zoom! = (zoom? ≠ ∅ ∧ zoom' = zoom?) ∨ zoom

=head2 onload_render

  OnloadRender
    HTML_OSM
    head! : S
    body! : S
  -----------------------------------------
    (#coordinates + #geojson + #heatmap_layers + #gpx_tracks + #choropleth_layers) > 0
    center ≠ ∅  ∨  ∃ valid ∈ coordinates • valid ∈ ValidCoord

=head1 LICENSE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

This program is released under the following licence: GPL2
If you use it,
please let me know.

=cut

1;

__END__
