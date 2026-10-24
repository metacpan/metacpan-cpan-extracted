package HTML::OSM;

use strict;
use warnings;

use autodie qw(:all);
use B ();
use Carp qw(carp croak);
use CHI;
use JSON::MaybeXS qw(decode_json encode_json);
use LWP::UserAgent;
use Object::Configure 0.15;
use Params::Get 0.13;
use Params::Validate::Strict 0.28;
use POSIX qw(localeconv setlocale LC_NUMERIC);
use Readonly;
use Scalar::Util qw(blessed);
use Time::HiRes qw(time);
use URI::Escape qw(uri_escape_utf8);

=head1 NAME

HTML::OSM - Generate an interactive OpenStreetMap with Leaflet.js

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

# CDN URLs pinned to tested versions.  Override via constructor params to use
# a self-hosted copy or a different version.
Readonly::Scalar my $LEAFLET_CSS_URL         => 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
Readonly::Scalar my $LEAFLET_JS_URL          => 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
Readonly::Scalar my $CLUSTER_JS_URL          => 'https://unpkg.com/leaflet.markercluster@1.5.3/dist/leaflet.markercluster.js';
Readonly::Scalar my $CLUSTER_CSS_URL         => 'https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.css';
Readonly::Scalar my $CLUSTER_DEFAULT_CSS_URL => 'https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.Default.css';
Readonly::Scalar my $HEATMAP_JS_URL          => 'https://unpkg.com/leaflet.heat@0.2.0/dist/leaflet-heat.js';
Readonly::Scalar my $GPX_JS_URL              => 'https://cdnjs.cloudflare.com/ajax/libs/leaflet-gpx/1.7.0/gpx.min.js';
Readonly::Scalar my $TILE_URL                => 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
Readonly::Scalar my $TILE_ATTRIBUTION        => '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
Readonly::Scalar my $NOMINATIM_HOST          => 'nominatim.openstreetmap.org/search';

# Rendering defaults, also used when a stored value is unusable at render time
Readonly::Scalar my $DEFAULT_ZOOM   => 12;
Readonly::Scalar my $DEFAULT_HEIGHT => '400px';
Readonly::Scalar my $DEFAULT_WIDTH  => '600px';
Readonly::Scalar my $DEFAULT_RADIUS => 25;
Readonly::Scalar my $DEFAULT_BLUR   => 15;

# A CSS length: a number with an optional unit, or 'auto'
Readonly::Scalar my $CSS_LENGTH => qr/\A(?:auto|[0-9]+(?:\.[0-9]+)?(?:px|%|em|rem|ex|ch|vh|vw|vmin|vmax|pt|pc|cm|mm|in)?)\z/;

# WGS-84 valid ranges
Readonly::Scalar my $LAT_MIN => -90;
Readonly::Scalar my $LAT_MAX =>  90;
Readonly::Scalar my $LON_MIN => -180;
Readonly::Scalar my $LON_MAX =>  180;
Readonly::Scalar my $ZOOM_MIN =>  0;
Readonly::Scalar my $ZOOM_MAX => 19;

# The highest maxZoom Leaflet supports on a tile layer
Readonly::Scalar my $MAX_ZOOM_LIMIT => 28;

# Circle markers: Leaflet's default path colour, and a hex colour check
Readonly::Scalar my $DEFAULT_CIRCLE_RADIUS => 8;
Readonly::Scalar my $DEFAULT_CIRCLE_COLOUR => '#3388ff';
Readonly::Scalar my $HEX_COLOUR            => qr/\A#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/;

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

=item * Tile server

C<tile_url> replaces the OpenStreetMap tile layer, so a map can use an
internal tile server or run on an air-gapped network.  It accepts the same
Leaflet placeholders as the default, for example
C<http://tiles.internal/{z}/{x}/{y}.png>.  The attribution remains the
OpenStreetMap credit, which is the usual requirement for OSM-derived tiles.
The in-page search box still calls Nominatim when a reader uses it; set
C<< search => 0 >> to leave it out.

=item * Maximum zoom

C<max_zoom> (0 to 28) stops readers zooming in further than the tile server
has tiles for.  Without it, Leaflet allows zooming past the server's coverage
and the map shows empty grey tiles.  When it is not given, no limit is set.

=item * Tile attribution

C<tile_attribution> replaces the credit shown in the corner of the map.
Set it when the tiles come from a provider that asks for a different
credit.  The value is HTML that Leaflet renders as it is, so pass only
trusted text.

=item * Nominatim contact address

C<email> is added to every Nominatim request the module makes, as the
Nominatim usage policy asks of heavy users.  It is not put into the rendered
page, so the in-page search box sends no address.

=item * Search box

By default the rendered page has a search box that sends whatever the reader
types to Nominatim, and a button that clears the markers it adds.  Set
C<< search => 0 >> to leave both out, so that nothing typed on the page leaves
the reader's machine.  The "Reset Map" button is always included.

=back

=head1 DESCRIPTION

C<HTML::OSM> builds an interactive map from OpenStreetMap tiles and the
Leaflet.js library.  Give it points as latitude and longitude, as place
names, or as geocoder result objects.  It can also draw GeoJSON shapes,
heatmaps, GPX tracks and choropleth (colour-filled region) layers, and can
group nearby markers into clusters.

Place names are turned into coordinates by an injected geocoder or, without
one, by the Nominatim service.  The answers are cached, and requests can be
spaced out with C<min_interval>.

C<onload_render()> returns two HTML fragments: one for the page's
C<< <head> >> and one for its C<< <body> >>.  The interface follows
L<HTML::GoogleMaps::V3>, so code written for that module needs few changes.

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
    email                   => { type => string,                    optional },
    geocoder                => { type => object, can => geocode,    optional },
    gpx_js_url              => { type => string,                    optional },
    heatmap_js_url          => { type => string,                    optional },
    height                  => { type => string,                    optional },
    host                    => { type => string,                    optional },
    js_url                  => { type => string,                    optional },
    logger                  => { type => object,                    optional },
    max_zoom                => { type => integer, min => 0, max => 28, optional },
    min_interval            => { type => number,  min => 0,         optional },
    search                  => { type => boolean,                   optional },
    tile_attribution        => { type => string,                    optional },
    tile_url                => { type => string,                    optional },
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
			email                   => { type => 'string',                         optional => 1 },
			geocoder                => { type => 'object',  can => 'geocode',      optional => 1 },
			gpx_js_url              => { type => 'string',                         optional => 1 },
			heatmap_js_url          => { type => 'string',                         optional => 1 },
			height                  => { type => 'string',                         optional => 1 },
			host                    => { type => 'string',                         optional => 1 },
			js_url                  => { type => 'string',                         optional => 1 },
			logger                  => { type => 'object',                         optional => 1 },
			max_zoom                => { type => 'integer', min => $ZOOM_MIN, max => $MAX_ZOOM_LIMIT, optional => 1 },
			min_interval            => { type => 'number',  min => 0,              optional => 1 },
			search                  => { type => 'boolean',                        optional => 1 },
			tile_attribution        => { type => 'string',                         optional => 1 },
			tile_url                => { type => 'string',                         optional => 1 },
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
		height                  => $DEFAULT_HEIGHT,
		host                    => $NOMINATIM_HOST,
		width                   => $DEFAULT_WIDTH,
		zoom                    => $DEFAULT_ZOOM,
		min_interval            => 0,
		last_request            => 0,
		cluster                 => 0,
		search                  => 1,
		css_url                 => $LEAFLET_CSS_URL,
		js_url                  => $LEAFLET_JS_URL,
		cluster_js_url          => $CLUSTER_JS_URL,
		cluster_css_url         => $CLUSTER_CSS_URL,
		cluster_default_css_url => $CLUSTER_DEFAULT_CSS_URL,
		heatmap_js_url          => $HEATMAP_JS_URL,
		gpx_js_url              => $GPX_JS_URL,
		tile_url                => $TILE_URL,
		tile_attribution        => $TILE_ATTRIBUTION,
		%{$params},
	}, $class;
}

=head2 add_marker

Add a point marker to the map.

    $map->add_marker([51.5074, -0.1278], html => 'London');
    $map->add_marker('Paris, France',    html => 'Paris');
    $map->add_marker($geo_coder_result);

Returns 1 on success, 0 if the point cannot be resolved or is out of range.
An empty address, or an arrayref that does not hold exactly two elements,
also returns 0.

=head3 API SPECIFICATION

=head4 INPUT

  point : arrayref [lat, lon] | string address | object with latitude()/longitude()
  html  : string   (optional popup label)
  icon  : string   (optional icon URL)

=head4 OUTPUT

  { type => integer, enum => [0, 1] }

=head3 MESSAGES

  | Message                                 | Meaning / Resolution                        |
  |-----------------------------------------|---------------------------------------------|
  | add_marker(): unknown point type: TYPE | Point is a ref type with no lat/lon methods |
  | Skipping invalid coordinate: (LAT, LON) | Warning: the point is not numeric or is out of range; 0 is returned |

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

	my ($lat, $lon, $params) = $self->_point_args('add_marker', @_);
	return 0 unless defined($lat);

	push @{$self->{coordinates}}, [$lat, $lon, $params->{'html'}, $params->{'icon'}];
	return 1;
}

=head2 add_circle_marker

Add a filled circle whose size in pixels can show a quantity, such as the
population of a town.

    $map->add_circle_marker([51.5074, -0.1278],
        html   => 'London',
        radius => 12,
        colour => '#e45c3a',
    );

The point may be anything C<add_marker()> accepts.  The radius is in screen
pixels, so a circle stays the same size as the reader zooms in and out.
With C<< cluster => 1 >>, circles join the same cluster group as the pin
markers.

Returns 1 on success, 0 if the point cannot be resolved or is out of range.

=head3 API SPECIFICATION

=head4 INPUT

  point  : arrayref [lat, lon] | string address | object with latitude()/longitude()
  html   : string   (optional popup label)
  radius : number > 0 and < 1e6   (optional, default 8)
  colour : string   hex #rrggbb or #rgb, any case   (optional, default '#3388ff')

=head4 OUTPUT

  { type => integer, enum => [0, 1] }

=head3 MESSAGES

  | Message                                             | Meaning / Resolution                        |
  |-----------------------------------------------------|---------------------------------------------|
  | add_circle_marker(): radius must be a positive number | radius is 0, negative, 1e6 or more, or not a plain number |
  | add_circle_marker(): invalid colour: VALUE          | colour is not a #rgb or #rrggbb hex string  |
  | add_circle_marker(): unknown point type: TYPE       | Point is a ref type with no lat/lon methods |
  | Skipping invalid coordinate: (LAT, LON)             | Warning: the point is not numeric or is out of range; 0 is returned |

=head3 EXAMPLES

    # Bubble whose area shows the population
    $map->add_circle_marker([$lat, $lon],
        html   => "$city ($pop)",
        radius => sqrt($pop / $max_pop) * 30,
        colour => '#e45c3a',
    );

    # Mixed map: pins for offices, circles for market size
    $map->add_marker([$lat1, $lon1], html => 'HQ');
    $map->add_circle_marker([$lat2, $lon2], html => 'Market A', radius => 20);

=cut

sub add_circle_marker
{
	my $self = shift;

	my ($lat, $lon, $params) = $self->_point_args('add_circle_marker', @_);

	# Check the options even when the point is unusable, so a bad radius or
	# colour is reported whatever the data
	my $radius = $params->{'radius'} // $DEFAULT_CIRCLE_RADIUS;
	my $checked = _positive_number($radius, undef);
	if(!defined($checked)) {
		my $msg = 'add_circle_marker(): radius must be a positive number';
		$self->{logger}->error($msg) if $self->{logger};
		croak $msg;
	}

	my $colour = $params->{'colour'} // $DEFAULT_CIRCLE_COLOUR;
	if(ref($colour) || $colour !~ $HEX_COLOUR) {
		my $msg = "add_circle_marker(): invalid colour: $colour";
		$self->{logger}->error($msg) if $self->{logger};
		croak $msg;
	}

	return 0 unless defined($lat);

	push @{$self->{circle_markers}}, [$lat, $lon, $params->{'html'}, $checked, lc($colour)];
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

    # Raw JSON string - decoded automatically
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
  radius : number  default 25 (a value that is not a positive number uses the default)
  blur   : number  default 15 (a value that is not a positive number uses the default)

=head4 OUTPUT

  { type => integer, value => 1 }

=head3 MESSAGES

  | Message                                 | Meaning / Resolution              |
  |-----------------------------------------|-----------------------------------|
  | add_heatmap: points must be an arrayref | First argument is not an arrayref |

=head3 EXAMPLES

    # Basic heatmap - [lat, lon] per point
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

  | Message                  | Meaning / Resolution     |
  |--------------------------|--------------------------|
  | add_gpx: url is required | No URL argument supplied |

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

  | Message                                     | Meaning / Resolution              |
  |---------------------------------------------|-----------------------------------|
  | add_choropleth: features must be an arrayref | First argument is not an arrayref |
  | add_choropleth: values must be a hashref     | Second argument is not a hashref  |

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

    # choropleth-only map - center() must be called explicitly
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

Returns 1 on success, 0 if the point cannot be resolved or is out of range.
An empty address also returns 0.

=head3 API SPECIFICATION

=head4 INPUT

  point : arrayref [lat, lon] | object with latitude()/longitude() | string address

=head4 OUTPUT

  { type => integer, enum => [0, 1] }

=head3 MESSAGES

  | Message                                            | Meaning / Resolution            |
  |----------------------------------------------------|---------------------------------|
  | center(): usage: point => [ latitude, longitude ]  | No point argument supplied      |
  | center(): point must have latitude and longitude   | Arrayref has != 2 elements      |
  | center(): unknown point type: TYPE                 | Ref type has no lat/lon methods |
  | Skipping invalid coordinate: (LAT, LON)            | Warning: point is not numeric or is out of range; 0 is returned |

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
		# An empty address cannot be resolved
		return 0 unless length($point);
		($lat, $lon) = $self->_fetch_coordinates($point);
	} else {
		my $msg = 'center(): unknown point type: ' . ref($point);
		$self->{logger}->error($msg) if $self->{logger};
		croak $msg;
	}

	return 0 unless defined($lat) && defined($lon);

	# Store the text form with a '.' decimal point, whatever the locale
	($lat, $lon) = (_num_str($lat), _num_str($lon));
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

C<$body_html> contains the search box (unless C<< search => 0 >>), control
buttons, map C<< <div> >>, and the initialisation C<< <script> >>.
Place it inside C<< <body>...</body> >> where the map should appear.

The rendered page provides:

=over 4

=item * A Nominatim-powered search box that adds temporary markers.
Left out when C<< search => 0 >>.

=item * A "Clear search markers" button that removes those temporary markers,
leaving static markers (added via C<add_marker>) intact.
Left out when C<< search => 0 >>.

=item * A "Reset Map" button that returns the view to the initial centre and zoom.

=back

Values that reach the object without going through C<new()>'s checks (from a
config file or a clone) are checked again here.  A C<zoom> that is not an
integer from 0 to 19 is replaced by 12, and a C<width> or C<height> that is
not a CSS length (such as C<600px>, C<100%> or C<auto>) is replaced by the
default.  A C<max_zoom> that is not an integer from 0 to 28 is ignored.  Each
replacement gives a warning.

=head3 API SPECIFICATION

=head4 INPUT

  (none - uses object state)

=head4 OUTPUT

  { type => list, elements => [string, string] }

=head3 MESSAGES

  | Message                                          | Meaning / Resolution                        |
  |--------------------------------------------------|---------------------------------------------|
  | No map data provided                             | No markers, circle markers, GeoJSON, heatmap, GPX, or choropleth added yet |
  | center() must be called when no point markers are provided | Non-marker-only render needs explicit centre |
  | Skipping invalid coordinate: (LAT, LON)          | Warning: a marker is not numeric or out of range; it is left off the map |
  | onload_render: invalid zoom 'Z', using 12        | Warning: zoom from a config file or clone is out of range |
  | onload_render: invalid max_zoom 'Z', ignoring it | Warning: max_zoom from a config file or clone is not an integer from 0 to 28 |
  | onload_render: invalid width 'W', using 600px    | Warning: width is not a CSS length |
  | onload_render: invalid height 'H', using 400px   | Warning: height is not a CSS length |
  | _fetch_coordinates: failed to decode Nominatim response: ERROR | Warning: Nominatim returned something that is not JSON; the marker is skipped |
  | _fetch_coordinates: unrecognised geocoder result type: TYPE | Warning: the injected geocoder returned an unknown type; the marker is skipped |

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
     A tuple with no coordinates and no address is discarded.
     Check circle markers the same way.
     Re-check zoom, max_zoom, width and height; fall back with a warning.
  3. Determine map centre: caller-supplied > computed midpoint of the bounds
     of the pin and circle markers.
     Croak if neither is available.
  4. Build <head>: Leaflet CSS + JS; inject cluster/heatmap/GPX plugin assets
     only when the corresponding layer type is present.
  5. Build <body>: search box and clear-search button (when search is on),
     reset button, map <div>.
  6. Initialise Leaflet map, tile layer (with maxZoom when max_zoom is set),
     and the searchMarkers array when search is on.
  7. Emit JS for each pin and circle marker (via one clusterGroup when
     cluster is set).
  8. Emit JS for each GeoJSON, heatmap, GPX, and choropleth layer.
  9. Attach event listeners: reset-view, and when search is on,
     clear-search-markers and search-on-Enter.
  10. Return ($head, $body).

=cut

sub onload_render
{
	my $self = shift;

	my $height            = _css_length('height', $self->{'height'}, $DEFAULT_HEIGHT);
	my $width             = _css_length('width',  $self->{'width'},  $DEFAULT_WIDTH);
	my $zoom              = $self->{'zoom'};
	my $coordinates       = $self->{coordinates}        || [];
	my $geojson_layers    = $self->{geojson}             || [];
	my $heatmap_layers    = $self->{heatmap_layers}      || [];
	my $gpx_tracks        = $self->{gpx_tracks}          || [];
	my $choropleth_layers = $self->{choropleth_layers}   || [];
	my $circle_markers    = $self->{circle_markers}      || [];

	unless(@$coordinates || @$geojson_layers || @$heatmap_layers
	                     || @$gpx_tracks     || @$choropleth_layers
	                     || @$circle_markers) {
		$self->{logger}->error('No map data provided') if $self->{logger};
		croak 'No map data provided';
	}

	# Config-file and clone values skip new()'s schema, so check zoom again
	# before it is put into the JavaScript.
	if(!defined($zoom) || $zoom !~ /\A[0-9]+\z/ || $zoom < $ZOOM_MIN || $zoom > $ZOOM_MAX) {
		carp sprintf("onload_render: invalid zoom '%s', using %d", $zoom // 'undef', $DEFAULT_ZOOM);
		$zoom = $DEFAULT_ZOOM;
	}

	# Geocode address strings; validate and discard bad numeric pairs.
	my @valid_coordinates;
	for my $coord (@$coordinates) {
		my ($lat, $lon, $label, $icon_url) = @$coord;
		if(!defined $lat || !defined $lon) {
			# No coordinates and no address: nothing to look up
			next unless defined($label) && length($label);
			($lat, $lon) = $self->_fetch_coordinates($label);
		}
		# Validate ALL coordinates here — including geocoder-returned ones.
		# A compromised geocoder or Nominatim response could return a crafted
		# lat/lon string that would inject JS if embedded without validation.
		next unless defined($lat) && defined($lon);
		($lat, $lon) = (_num_str($lat), _num_str($lon));
		next unless _validate($lat, $lon);
		push @valid_coordinates, [$lat, $lon, $label, $icon_url];
	}

	# add_circle_marker checked these, but a clone can bring in anything
	my @valid_circles;
	for my $circle (@$circle_markers) {
		my ($lat, $lon, $label, $radius, $colour) = @$circle;
		next unless defined($lat) && defined($lon);
		($lat, $lon) = (_num_str($lat), _num_str($lon));
		next unless _validate($lat, $lon);
		$radius = _positive_number($radius, $DEFAULT_CIRCLE_RADIUS);
		$colour = $DEFAULT_CIRCLE_COLOUR unless defined($colour) && !ref($colour) && $colour =~ $HEX_COLOUR;
		push @valid_circles, [$lat, $lon, $label, $radius, lc($colour)];
	}

	# Only an integer in Leaflet's range is put into the tile layer options
	my $max_zoom = $self->{'max_zoom'};
	if(defined($max_zoom) && ($max_zoom !~ /\A[0-9]+\z/ || $max_zoom > $MAX_ZOOM_LIMIT)) {
		carp "onload_render: invalid max_zoom '$max_zoom', ignoring it";
		undef $max_zoom;
	}
	my $max_zoom_js = defined($max_zoom) ? ",\n\t\t\t\tmaxZoom: $max_zoom" : '';

	# A config file can give the words 'false', 'no' or 'off'
	my $search = $self->{'search'};
	$search = 0 if defined($search) && $search =~ /\A(?:false|no|off)\z/i;

	# Determine map centre: caller-set wins; else compute from marker bounds.
	my ($center_lat, $center_lon);
	if($self->{'center'}) {
		($center_lat, $center_lon) = @{$self->{'center'}};
	} elsif(@valid_coordinates || @valid_circles) {
		my ($min_lat, $min_lon, $max_lat, $max_lon) = (90, 180, -90, -180);
		for my $c (@valid_coordinates, @valid_circles) {
			# Convert with _num_val: some perls read '51.5074' as 51 under de_DE
			my ($lat, $lon) = (_num_val($c->[0]), _num_val($c->[1]));
			$min_lat = $lat if $lat < $min_lat;
			$max_lat = $lat if $lat > $max_lat;
			$min_lon = $lon if $lon < $min_lon;
			$max_lon = $lon if $lon > $max_lon;
		}
		$center_lat = ($min_lat + $max_lat) / 2;
		$center_lon = ($min_lon + $max_lon) / 2;
	} else {
		croak 'center() must be called when no point markers are provided';
	}
	# The midpoint is a new number, so it needs the same treatment as markers
	($center_lat, $center_lon) = (_num_str($center_lat), _num_str($center_lon));

	# --- <head> ---
	my %url = map { $_ => _html_attr($self->{$_}) }
		qw(css_url js_url cluster_css_url cluster_default_css_url cluster_js_url heatmap_js_url gpx_js_url);
	my $head = qq{
		<link rel="stylesheet" href="$url{css_url}" />
		<script src="$url{js_url}"></script>
	};

	if($self->{cluster}) {
		$head .= qq{
		<link rel="stylesheet" href="$url{cluster_css_url}" />
		<link rel="stylesheet" href="$url{cluster_default_css_url}" />
		<script src="$url{cluster_js_url}"></script>
		};
	}
	$head .= qq{\t\t<script src="$url{heatmap_js_url}"></script>\n} if @$heatmap_layers;
	$head .= qq{\t\t<script src="$url{gpx_js_url}"></script>\n}     if @$gpx_tracks;

	if($search) {
		$head .= qq{
		<style>
			#map { width: $width; height: $height; }
			#search-box { margin: 10px; padding: 5px; }
			#reset-button, #clear-search-button { margin: 10px; padding: 5px; cursor: pointer; }
		</style>
		};
	} else {
		$head .= qq{
		<style>
			#map { width: $width; height: $height; }
			#reset-button { margin: 10px; padding: 5px; cursor: pointer; }
		</style>
		};
	}

	# --- <body> ---
	my $tile_url         = _js_string($self->{tile_url});
	my $tile_attribution = _js_string($self->{tile_attribution});
	my $body = '';
	if($search) {
		$body .= qq{
		<input type="text" id="search-box" placeholder="Enter location">
		<button id="clear-search-button">Clear search markers</button>};
	}
	$body .= qq{
		<button id="reset-button">Reset Map</button>
		<div id="map"></div>
		<script>
			var map = L.map('map').setView([$center_lat, $center_lon], $zoom);
			L.tileLayer('$tile_url', {
				attribution: '$tile_attribution'$max_zoom_js
			}).addTo(map);
	};
	$body .= "\n\t\t\tvar searchMarkers = [];\n" if $search;

	# Point and circle markers — optionally grouped into one cluster layer.
	my $clustered = $self->{cluster} && (@valid_coordinates || @valid_circles);
	$body .= "\t\t\tvar clusterGroup = L.markerClusterGroup();\n" if $clustered;
	if(@valid_coordinates) {

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
	}

	for my $circle (@valid_circles) {
		my ($lat, $lon, $label, $radius, $colour) = @$circle;
		my $popup = (defined($label) && length($label))
			? ".bindPopup('" . _js_string($label) . "')"
			: '';
		my $circle_js = "L.circleMarker([$lat, $lon], { radius: $radius, color: '$colour', fillColor: '$colour', fillOpacity: 0.7 })$popup";
		if($self->{cluster}) {
			$body .= "\t\t\tclusterGroup.addLayer($circle_js);\n";
		} else {
			$body .= "\t\t\t$circle_js.addTo(map);\n";
		}
	}

	$body .= "\t\t\tmap.addLayer(clusterGroup);\n" if $clustered;

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
		# Only plain positive numbers reach the JavaScript
		my $radius = _positive_number($opts->{radius}, $DEFAULT_RADIUS);
		my $blur   = _positive_number($opts->{blur},   $DEFAULT_BLUR);
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
				map.setView([$center_lat, $center_lon], $zoom);
			});
	};

	if($search) {
		$body .= qq{
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
		};
	}
	$body .= "\t\t</script>\n";

	return ($head, $body);
}

# _point_args: Split a marker method's arguments into a point and options,
#          and resolve the point to coordinates.
# Purpose: add_marker and add_circle_marker take the same kinds of point.
# Entry:   $self, $caller (method name for messages), then the caller's @_.
# Exit:    ($lat, $lon, \%params) with dot-decimal, range-checked coordinates;
#          (undef, undef, \%params) when the point cannot be used.
# Side Effects: May call the geocoder; croaks on an unknown point type; _validate carps.
sub _point_args
{
	my ($self, $caller, @args) = @_;
	my ($params, $point);

	if(ref($args[0]) eq 'ARRAY') {
		$point  = shift @args;
		$params = Params::Get::get_params(undef, \@args) || {};
		# Single-element arrayref is a wrapped address string
		$point  = $point->[0] if scalar(@{$point}) == 1;
	} elsif(blessed($args[0]) && $args[0]->can('latitude')) {
		# Geo object as first positional arg: extract before Params::Get sees it,
		# otherwise Params::Get mistakes the blessed hashref for the params hash.
		$point  = shift @args;
		$params = Params::Get::get_params(undef, \@args) || {};
	} elsif(defined($args[0]) && !ref($args[0]) && scalar(@args) % 2 != 0) {
		# Plain string as first positional arg, optionally followed by key-value pairs.
		# An odd total count signals a leading positional; even count means all key-value.
		$point  = shift @args;
		$params = Params::Get::get_params(undef, \@args) || {};
	} else {
		$params = Params::Get::get_params('point', @args);
		$point  = $params->{'point'};
	}
	$params ||= {};

	my ($lat, $lon);

	if(ref($point) eq 'ARRAY') {
		return (undef, undef, $params) if scalar(@{$point}) != 2;
		($lat, $lon) = @{$point};
	} elsif(!ref($point)) {
		# An empty or missing address cannot be resolved
		return (undef, undef, $params) unless defined($point) && length($point);
		($lat, $lon) = $self->_fetch_coordinates($point);
	} elsif($point->can('latitude')) {
		($lat, $lon) = ($point->latitude(), $point->longitude());
	} else {
		my $msg = "$caller(): unknown point type: " . ref($point);
		$self->{logger}->error($msg) if $self->{logger};
		croak $msg;
	}

	return (undef, undef, $params) unless defined($lat) && defined($lon);

	# Store the text form with a '.' decimal point, whatever the locale
	($lat, $lon) = (_num_str($lat), _num_str($lon));
	return (undef, undef, $params) unless _validate($lat, $lon);

	return ($lat, $lon, $params);
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

	# Configure only a UA we create; a caller's UA is used as supplied
	my $ua = $self->{'ua'};
	if(!$ua) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
		$ua->env_proxy(1);
	}

	my $url = 'https://' . $self->{'host'} . '?format=json&q=' . uri_escape_utf8($location);
	$url .= '&email=' . uri_escape_utf8($self->{'email'}) if $self->{'email'};
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
	my ($lat, $lon) = map { _num_str($_) } @_;

	# Require at least one digit (rejects empty string — unlike \d* which matches '').
	# Leading-decimal notation (e.g. -.5167) is valid per Changes 0.05.
	# \z (not $) prevents a trailing \n from sneaking through: $ matches before
	# a final newline, which would make "0\n" valid and embed a newline in JS.
	my $numeric = qr/^-?(?:\d+(?:\.\d+)?|\.\d+)\z/;

	# Range checks use _num_val, which does not depend on the locale
	my $ok = defined($lat) && defined($lon)
	      && $lat =~ $numeric && $lon =~ $numeric
	      && _num_val($lat) >= $LAT_MIN && _num_val($lat) <= $LAT_MAX
	      && _num_val($lon) >= $LON_MIN && _num_val($lon) <= $LON_MAX;

	carp(sprintf 'Skipping invalid coordinate: (%s, %s)',
	     $lat // 'undef', $lon // 'undef')
		if !$ok && defined($lat) && defined($lon);

	return $ok ? 1 : 0;
}

# _html_json: Encode data as JSON and make the result safe for embedding in a
# <script> block.  JSON encoders do not escape '/' by default, so a value like
# '</script>' would close the enclosing script tag and allow HTML injection.
# Escaping every '</' as '<\/' prevents this without altering the decoded value.
# Encoding runs under the C numeric locale: some encoders print numbers through
# the C library or Perl's own stringification, and under a locale such as
# de_DE 0.5 could come out as 0,5, which JSON reads as two numbers.
# Entry:   Any Perl data structure accepted by encode_json.
# Exit:    JSON string safe for direct insertion inside a <script> block.
# Side Effects: LC_NUMERIC is switched to 'C' for the encode and then restored.
sub _html_json
{
	my $data = shift;

	my $saved_error  = $@;
	my $saved_locale = setlocale(LC_NUMERIC);
	setlocale(LC_NUMERIC, 'C');
	my $j   = eval { encode_json($data) };
	my $err = $@;
	setlocale(LC_NUMERIC, $saved_locale) if defined($saved_locale);
	die $err unless defined($j);
	$@ = $saved_error;

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
	$s =~ s/\r/\\r/g;     # a lone carriage return also ends a JS string
	$s =~ s|</|<\\/|g;    # prevent </script> injection
	return $s;
}

# _html_attr: Escape a Perl string for safe embedding in a double-quoted HTML attribute.
# Purpose: Stop a configured CDN URL from closing the attribute or the tag.
# Entry:   Any scalar (undef becomes '').
# Exit:    String with &, <, > and " replaced by entities.
sub _html_attr
{
	my $s = shift // '';
	$s =~ s/&/&amp;/g;    # escape ampersand first to avoid double-escaping
	$s =~ s/</&lt;/g;
	$s =~ s/>/&gt;/g;
	$s =~ s/"/&quot;/g;
	return $s;
}

# _css_length: Check a width or height before it is put into the <style> block.
# Purpose: Values from a config file or a clone skip new()'s schema, so a value
#          such as '1px}</style><script>' could otherwise reach the page.
# Entry:   ($name, $value, $default) - name is used only in the warning.
# Exit:    $value when it is a CSS length; otherwise $default.
# Side Effects: carp when a non-empty value is replaced.
sub _css_length
{
	my ($name, $value, $default) = @_;

	return $default unless defined($value) && length($value);
	return $value if $value =~ $CSS_LENGTH;

	carp "onload_render: invalid $name '$value', using $default";
	return $default;
}

# _positive_number: Return $value as text when it is a positive number.
# Purpose: Heatmap options go straight into the JavaScript, so anything that
#          is not a plain number must not reach it.  The check works on the
#          text form so it does not depend on the locale (see _num_val).
# Entry:   ($value, $default).
# Exit:    $value as a dot-decimal string, or $default when $value is missing,
#          not a plain decimal number, <= 0 or >= 1e6.
sub _positive_number
{
	my ($value, $default) = @_;

	return $default unless defined($value) && !ref($value);

	my $str = _num_str($value);
	$str =~ s/\A\s+|\s+\z//g;
	# Plain decimals only: rejects signs, exponents, 'Inf' and 'NaN'
	return $default unless $str =~ /\A(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)\z/;

	my $number = _num_val($str);
	return $default unless $number > 0 && $number < 1e6;
	return _num_str($number);
}

# _num_str: Return a number as text with '.' as the decimal point.
# Purpose: Perl should print numbers with a '.' whatever the locale, but some
#          builds (seen with Perl 5.38.0 on macOS) use the LC_NUMERIC decimal
#          point, so 51.5074 prints as '51,5074' under de_DE.  That fails
#          _validate, and in JavaScript '[51,5074, -0,1278]' is four numbers.
# Entry:   Any scalar.
# Exit:    A value Perl holds as a number comes back as text with a '.'
#          decimal point; anything else (strings, undef, refs) is unchanged.
sub _num_str
{
	my $value = shift;

	return $value if !defined($value) || ref($value);

	# Only a value Perl holds as a number can have been printed with a locale
	# decimal point; a string such as '51,5' never gets these flags.
	my $flags = B::svref_2object(\$value)->FLAGS;
	return $value unless $flags & (B::SVf_IOK() | B::SVf_NOK());

	my $str   = "$value";
	my $radix = (localeconv() || {})->{decimal_point};
	$str =~ s/\Q$radix\E/./ if defined($radix) && length($radix) && $radix ne '.';
	$str =~ tr/,/./;    # Perl never groups digits, so a comma can only be a decimal point
	return $str;
}

# _num_val: Convert a decimal string such as '-0.1278' to a number.
# Purpose: The perls that print numbers with the locale's decimal point also
#          read them that way, so under de_DE '51.5074' + 0 is 51.  Building
#          the value from its whole and fractional digit strings uses only
#          integer conversion, which no locale affects.
# Entry:   A number, or a string in the form _validate accepts.
# Exit:    The numeric value.  Anything else falls back to Perl's own conversion.
sub _num_val
{
	my $str = _num_str(shift);

	my ($sign, $whole, $frac) = $str =~ /\A(-?)([0-9]*)(?:\.([0-9]+))?\z/;
	if(!defined($sign) || (!length($whole) && !defined($frac))) {
		no warnings 'numeric';
		return 0 + $str;
	}

	my $value = length($whole) ? 0 + $whole : 0;
	$value += $frac / (10 ** length($frac)) if defined($frac);
	return $sign ? -$value : $value;
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
C<onload_render()> checks C<zoom>, C<max_zoom>, C<width> and C<height> again and
HTML-escapes the CDN URLs, so a bad value cannot inject markup into the page.

=item * B<One map per page>: The rendered HTML uses fixed element IDs
(C<map>, C<search-box>, C<clear-search-button> and C<reset-button>), so two
maps on the same page will clash.

=item * B<Clustered circle markers>: With C<< cluster => 1 >>, circle markers
are grouped with the pin markers, so at low zoom levels a cluster count is
shown in place of the circles' sizes.  Leave C<cluster> off for a bubble map
whose sizes should always be visible.

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

Please report problems and ask questions at
L<https://github.com/nigelhorne/HTML-OSM/issues>.

You can find documentation for this module with the perldoc command.

    perldoc HTML::OSM

You can also look for information at MetaCPAN:
L<https://metacpan.org/dist/HTML-OSM>.

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

=head2 add_choropleth

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
