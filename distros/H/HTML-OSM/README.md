## Name

HTML::OSM - Generate an interactive OpenStreetMap with Leaflet.js

## Version

Version 0.12

## Synopsis

```perl
use HTML::OSM;

my $map = HTML::OSM->new(
    coordinates => [
        [37.7749, -122.4194, 'San Francisco'],
        [undef,   undef,     'Paris'],
    ],
    zoom => 10,
);
my ($head, $body) = $map->onload_render();
```

- Caching

    Geocode results are cached via [CHI](https://metacpan.org/pod/CHI) (default: in-memory, 1-day TTL).
    Supply your own `cache` object to persist across processes.

- Rate-Limiting

    Set `min_interval` (seconds) to throttle outbound Nominatim calls
    and comply with the API fair-use policy.

- Tile server

    `tile_url` replaces the OpenStreetMap tile layer, so a map can use an
    internal tile server or run on an air-gapped network.  It accepts the same
    Leaflet placeholders as the default, for example
    `http://tiles.internal/{z}/{x}/{y}.png`.  The attribution remains the
    OpenStreetMap credit, which is the usual requirement for OSM-derived tiles.
    The in-page search box still calls Nominatim when a reader uses it; set
    `search => 0` to leave it out.

- Maximum zoom

    `max_zoom` (0 to 28) stops readers zooming in further than the tile server
    has tiles for.  Without it, Leaflet allows zooming past the server's coverage
    and the map shows empty grey tiles.  When it is not given, no limit is set.

- Tile attribution

    `tile_attribution` replaces the credit shown in the corner of the map.
    Set it when the tiles come from a provider that asks for a different
    credit.  The value is HTML that Leaflet renders as it is, so pass only
    trusted text.

- Nominatim contact address

    `email` is added to every Nominatim request the module makes, as the
    Nominatim usage policy asks of heavy users.  It is not put into the rendered
    page, so the in-page search box sends no address.

- Search box

    By default the rendered page has a search box that sends whatever the reader
    types to Nominatim, and a button that clears the markers it adds.  Set
    `search => 0` to leave both out, so that nothing typed on the page leaves
    the reader's machine.  The "Reset Map" button is always included.

## Description

`HTML::OSM` builds an interactive map from OpenStreetMap tiles and the
Leaflet.js library.  Give it points as latitude and longitude, as place
names, or as geocoder result objects.  It can also draw GeoJSON shapes,
heatmaps, GPX tracks and choropleth (colour-filled region) layers, and can
group nearby markers into clusters.

Place names are turned into coordinates by an injected geocoder or, without
one, by the Nominatim service.  The answers are cached, and requests can be
spaced out with `min_interval`.

`onload_render()` returns two HTML fragments: one for the page's
`<head>` and one for its `<body>`.  The interface follows
[HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3), so code written for that module needs few changes.

## Subroutines/Methods

### New

Construct a new `HTML::OSM` object.

```perl
my $map = HTML::OSM->new(%params);
my $map = HTML::OSM->new(\%params);
```

Both method-style (`HTML::OSM->new(...)`) and function-style
(`HTML::OSM::new(...)`) calls are supported.
Calling `$existing_obj->new(%overrides)` performs a shallow clone,
merging `%overrides` onto the existing object's state without re-validating.

#### Api Specification

##### Input

```perl
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
```

##### Output

```perl
{ type => object, isa => 'HTML::OSM' }
```

#### Messages

```
| Message                                        | Meaning / Resolution                          |
|------------------------------------------------|-----------------------------------------------|
| (validation error from Params::Validate::Strict) | A param has the wrong type or is out of range |
```

#### Pseudocode

```perl
1. If $class is neither a package name nor a blessed ref, treat as
   function-style call: prepend $class back onto @_ and use __PACKAGE__.
2. If $class is a blessed ref (clone call): merge override params onto a
   shallow copy and return immediately, bypassing schema validation.
3. Validate all supplied args against the declared schema.
4. Merge config-file settings via Object::Configure.
5. Resolve the cache: caller-supplied object, or in-memory CHI instance.
6. Bless and return with Readonly CDN constants as defaults.
```

### Add\_Marker

Add a point marker to the map.

```perl
$map->add_marker([51.5074, -0.1278], html => 'London');
$map->add_marker('Paris, France',    html => 'Paris');
$map->add_marker($geo_coder_result);
```

Returns 1 on success, 0 if the point cannot be resolved or is out of range.
An empty address, or an arrayref that does not hold exactly two elements,
also returns 0.

#### Api Specification

##### Input

```
point : arrayref [lat, lon] | string address | object with latitude()/longitude()
html  : string   (optional popup label)
icon  : string   (optional icon URL)
```

##### Output

```perl
{ type => integer, enum => [0, 1] }
```

#### Messages

```
| Message                                 | Meaning / Resolution                        |
|-----------------------------------------|---------------------------------------------|
| add_marker(): unknown point type: TYPE | Point is a ref type with no lat/lon methods |
| Skipping invalid coordinate: (LAT, LON) | Warning: the point is not numeric or is out of range; 0 is returned |
```

#### Examples

```perl
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
```

### Add\_Circle\_Marker

Add a filled circle whose size in pixels can show a quantity, such as the
population of a town.

```perl
$map->add_circle_marker([51.5074, -0.1278],
    html   => 'London',
    radius => 12,
    colour => '#e45c3a',
);
```

The point may be anything `add_marker()` accepts.  The radius is in screen
pixels, so a circle stays the same size as the reader zooms in and out.
With `cluster => 1`, circles join the same cluster group as the pin
markers.

Returns 1 on success, 0 if the point cannot be resolved or is out of range.

#### Api Specification

##### Input

```
point  : arrayref [lat, lon] | string address | object with latitude()/longitude()
html   : string   (optional popup label)
radius : number > 0 and < 1e6   (optional, default 8)
colour : string   hex #rrggbb or #rgb, any case   (optional, default '#3388ff')
```

##### Output

```perl
{ type => integer, enum => [0, 1] }
```

#### Messages

```
| Message                                             | Meaning / Resolution                        |
|-----------------------------------------------------|---------------------------------------------|
| add_circle_marker(): radius must be a positive number | radius is 0, negative, 1e6 or more, or not a plain number |
| add_circle_marker(): invalid colour: VALUE          | colour is not a #rgb or #rrggbb hex string  |
| add_circle_marker(): unknown point type: TYPE       | Point is a ref type with no lat/lon methods |
| Skipping invalid coordinate: (LAT, LON)             | Warning: the point is not numeric or is out of range; 0 is returned |
```

#### Examples

```perl
# Bubble whose area shows the population
$map->add_circle_marker([$lat, $lon],
    html   => "$city ($pop)",
    radius => sqrt($pop / $max_pop) * 30,
    colour => '#e45c3a',
);

# Mixed map: pins for offices, circles for market size
$map->add_marker([$lat1, $lon1], html => 'HQ');
$map->add_circle_marker([$lat2, $lon2], html => 'Market A', radius => 20);
```

### Add\_Geojson

Add a GeoJSON layer to the map.

```perl
$map->add_geojson(\%data, style => { color => '#ff0000' }, popup => 'name');
```

The first argument may be a hashref/arrayref (GeoJSON structure) or a JSON string.
Returns 1 on success.

#### Api Specification

##### Input

```
data  : hashref | arrayref | string (JSON)
style : hashref   Leaflet path-style options (color, weight, fillColor, fillOpacity)
popup : string    Feature property name whose value becomes the popup text
```

##### Output

```perl
{ type => integer, value => 1 }
```

#### Messages

```
| Message              | Meaning / Resolution            |
|----------------------|---------------------------------|
| (JSON parse error)   | data string is not valid JSON   |
```

#### Examples

```perl
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
```

### Add\_Heatmap

Add a heatmap layer to the map.

```perl
$map->add_heatmap([[51.5, -0.1, 0.8], [51.6, -0.2, 0.5]], radius => 25);
```

Each point is `[$lat, $lon]` or `[$lat, $lon, $intensity]` (intensity: 0-1).
Requires the Leaflet.heat plugin (`heatmap_js_url`).
Returns 1 on success.

#### Api Specification

##### Input

```
points : arrayref of ([lat, lon] | [lat, lon, intensity])
radius : number  default 25 (a value that is not a positive number uses the default)
blur   : number  default 15 (a value that is not a positive number uses the default)
```

##### Output

```perl
{ type => integer, value => 1 }
```

#### Messages

```
| Message                                 | Meaning / Resolution              |
|-----------------------------------------|-----------------------------------|
| add_heatmap: points must be an arrayref | First argument is not an arrayref |
```

#### Examples

```perl
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
```

### Add\_Gpx

Add a GPX track to the map from a URL.

```
$map->add_gpx('https://example.com/track.gpx');
```

The map view is auto-fitted to the track bounds after loading.
Requires the leaflet-gpx plugin (`gpx_js_url`).
Returns 1 on success.

#### Api Specification

##### Input

```
url : string  URL of the GPX file (required)
```

##### Output

```perl
{ type => integer, value => 1 }
```

#### Messages

```
| Message                  | Meaning / Resolution     |
|--------------------------|--------------------------|
| add_gpx: url is required | No URL argument supplied |
```

#### Examples

```
# Add a GPX track from a public URL; the map auto-fits to its bounds
$map->add_gpx('https://example.com/route.gpx');

# Multiple tracks on the same map
$map->add_gpx('https://example.com/morning-run.gpx');
$map->add_gpx('https://example.com/evening-walk.gpx');
```

### Add\_Choropleth

Add a choropleth (data-driven colour fill) layer to the map.

```perl
$map->add_choropleth(
    \@geojson_features,
    { England => 100, Scotland => 80, Wales => 60 },
    key   => 'name',
    scale => ['#ffffcc', '#a1dab4', '#41b6c4', '#2c7fb8', '#253494'],
);
```

Colours are pre-computed in Perl and baked into the emitted JavaScript.
No extra browser plugin is required.
Returns 1 on success.

#### Api Specification

##### Input

```perl
features : arrayref of GeoJSON Feature hashrefs  (required)
values   : hashref  { feature_property_value => numeric_value }  (required)
key      : string   feature property to match against values  (default: 'name')
scale    : arrayref hex-colour strings low-to-high  (default: 5-step YlGnBu)
```

##### Output

```perl
{ type => integer, value => 1 }
```

#### Messages

```
| Message                                     | Meaning / Resolution              |
|---------------------------------------------|-----------------------------------|
| add_choropleth: features must be an arrayref | First argument is not an arrayref |
| add_choropleth: values must be a hashref     | Second argument is not a hashref  |
```

#### Examples

```perl
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
```

### Center

Set the map centre to a given point.

```
$map->center([40.7128, -74.0060]);
$map->center($geo_object);
$map->center('Berlin, Germany');
```

Returns 1 on success, 0 if the point cannot be resolved or is out of range.
An empty address also returns 0.

#### Api Specification

##### Input

```
point : arrayref [lat, lon] | object with latitude()/longitude() | string address
```

##### Output

```perl
{ type => integer, enum => [0, 1] }
```

#### Messages

```perl
| Message                                            | Meaning / Resolution            |
|----------------------------------------------------|---------------------------------|
| center(): usage: point => [ latitude, longitude ]  | No point argument supplied      |
| center(): point must have latitude and longitude   | Arrayref has != 2 elements      |
| center(): unknown point type: TYPE                 | Ref type has no lat/lon methods |
| Skipping invalid coordinate: (LAT, LON)            | Warning: point is not numeric or is out of range; 0 is returned |
```

#### Examples

```perl
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
```

### Zoom

Get or set the zoom level (0 = world, 19 = building).

```perl
$map->zoom(10);
my $z = $map->zoom();
```

#### Api Specification

##### Input

```perl
{ zoom => { type => integer, min => 0, max => 19, optional => 1 } }
```

##### Output

```perl
{ type => integer, min => 0, max => 19 }
```

#### Messages

```
| Message                      | Meaning / Resolution                      |
|------------------------------|-------------------------------------------|
| (Params::Validate::Strict)   | zoom is not an integer or is out of range |
```

#### Examples

```perl
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
```

### Onload\_Render

Render the map and return a two-element list suitable for embedding in HTML.

```perl
my ($head_html, $body_html) = $map->onload_render();
```

`$head_html` contains the Leaflet CSS, JavaScript, and plugin assets.
Place it inside `<head>...</head>`.

`$body_html` contains the search box (unless `search => 0`), control
buttons, map `<div>`, and the initialisation `<script>`.
Place it inside `<body>...</body>` where the map should appear.

The rendered page provides:

- A Nominatim-powered search box that adds temporary markers.
Left out when `search => 0`.
- A "Clear search markers" button that removes those temporary markers,
leaving static markers (added via `add_marker`) intact.
Left out when `search => 0`.
- A "Reset Map" button that returns the view to the initial centre and zoom.

Values that reach the object without going through `new()`'s checks (from a
config file or a clone) are checked again here.  A `zoom` that is not an
integer from 0 to 19 is replaced by 12, and a `width` or `height` that is
not a CSS length (such as `600px`, `100%` or `auto`) is replaced by the
default.  A `max_zoom` that is not an integer from 0 to 28 is ignored.  Each
replacement gives a warning.

#### Api Specification

##### Input

```
(none - uses object state)
```

##### Output

```perl
{ type => list, elements => [string, string] }
```

#### Messages

```
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
```

#### Examples

```perl
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
```

#### Pseudocode

```
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
```

## Limitations

- **Per-marker removal**: Markers added via `add_marker()` cannot yet be
removed individually by clicking them.  The "Clear search markers" button only
removes markers added by the in-page Nominatim search box.
- **Clone validation**: The clone path (`$obj->new(%overrides)`)
bypasses the Params::Validate::Strict schema so subclasses and internal callers
can merge arbitrary state.  Callers are responsible for passing valid overrides.
- **Config-file params unvalidated**: Keys injected by
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) from a config file are not re-run through the schema, so
a malformed config file can introduce invalid types at runtime.
`onload_render()` checks `zoom`, `max_zoom`, `width` and `height` again and
HTML-escapes the CDN URLs, so a bad value cannot inject markup into the page.
- **One map per page**: The rendered HTML uses fixed element IDs
(`map`, `search-box`, `clear-search-button` and `reset-button`), so two
maps on the same page will clash.
- **Clustered circle markers**: With `cluster => 1`, circle markers
are grouped with the pin markers, so at low zoom levels a cluster count is
shown in place of the circles' sizes.  Leave `cluster` off for a bubble map
whose sizes should always be visible.
- **Private-method encapsulation**: `_fetch_coordinates`, `_validate`,
and `_js_string` are named with a leading underscore by convention only.
Using [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) in `enforce` mode would make the contract explicit, but
that module is not yet listed as a dependency to avoid breaking white-box tests
in `t/mock.t`.
- **Routing**: Turn-by-turn routing (Leaflet Routing Machine / OSRM) is
explicitly out of scope for this module and will not be added here.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Bugs

Please report bugs at [https://github.com/nigelhorne/HTML-OSM/issues](https://github.com/nigelhorne/HTML-OSM/issues).

## See Also

- [https://wiki.openstreetmap.org/wiki/API](https://wiki.openstreetmap.org/wiki/API)
- [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3) - the interface this module mirrors for compatibility.
- [https://leafletjs.com/](https://leafletjs.com/)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/HTML-OSM/coverage/)

## Support

This module is provided as-is without any warranty.

Please report problems and ask questions at
[https://github.com/nigelhorne/HTML-OSM/issues](https://github.com/nigelhorne/HTML-OSM/issues).

You can find documentation for this module with the perldoc command.

```
perldoc HTML::OSM
```

You can also look for information at MetaCPAN:
[https://metacpan.org/dist/HTML-OSM](https://metacpan.org/dist/HTML-OSM).

### Todo

Allow per-marker removal via clicking on a marker.

## Formal Specification

### New

```
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
```

### Add\_Marker

```
AddMarker
  ΔHTML_OSM
  point? : (ℝ x ℝ) ∪ S ∪ GeoObject
  result! : {0, 1}
-----------------------------------------
  result! = 1 ⟺ point? resolves to (lat, lon) ∈ ValidCoord
  result! = 1 ⟹ coordinates' = coordinates ⌢ ⟨(lat, lon, label, icon)⟩
```

### Add\_Geojson

```
AddGeoJSON
  ΔHTML_OSM
  data?  : GeoJSONStruct ∪ S
  style? : StyleMap ∪ {∅}
  popup? : S ∪ {∅}
-----------------------------------------
  geojson' = geojson ⌢ ⟨{data, style, popup}⟩
```

### Add\_Heatmap

```
AddHeatmap
  ΔHTML_OSM
  points? : iseq (ℝ x ℝ x [0,1])
-----------------------------------------
  heatmap_layers' = heatmap_layers ⌢ ⟨{points, radius, blur}⟩
```

### Add\_Gpx

```
AddGPX
  ΔHTML_OSM
  url? : S | url? ≠ ''
-----------------------------------------
  gpx_tracks' = gpx_tracks ⌢ ⟨url?⟩
```

### Add\_Choropleth

```
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
```

### Center

```
Center
  ΔHTML_OSM
  point? : (ℝ x ℝ) ∪ S ∪ GeoObject
  result! : {0, 1}
-----------------------------------------
  result! = 1 ⟺ point? resolves to (lat, lon) ∈ ValidCoord
  result! = 1 ⟹ center' = (lat, lon)
```

### Zoom

```
Zoom
  ΔHTML_OSM
  zoom? : Z ∪ {∅}
  zoom! : Z
-----------------------------------------
  zoom? ≠ ∅ ⟹ ZOOM_MIN <= zoom? <= ZOOM_MAX
  zoom! = (zoom? ≠ ∅ ∧ zoom' = zoom?) ∨ zoom
```

### Onload\_Render

```
OnloadRender
  HTML_OSM
  head! : S
  body! : S
-----------------------------------------
  (#coordinates + #geojson + #heatmap_layers + #gpx_tracks + #choropleth_layers) > 0
  center ≠ ∅  ∨  ∃ valid ∈ coordinates • valid ∈ ValidCoord
```

## License and Copyright

Copyright 2025-2026 Nigel Horne.

This program is released under the following licence: GPL2
If you use it,
please let me know.
