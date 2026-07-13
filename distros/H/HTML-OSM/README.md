# NAME

HTML::OSM - Generate an interactive OpenStreetMap with Leaflet.js

# VERSION

Version 0.10

# SYNOPSIS

    use HTML::OSM;

    my $map = HTML::OSM->new(
        coordinates => [
            [37.7749, -122.4194, 'San Francisco'],
            [undef,   undef,     'Paris'],
        ],
        zoom => 10,
    );
    my ($head, $body) = $map->onload_render();

- Caching

    Geocode results are cached via [CHI](https://metacpan.org/pod/CHI) (default: in-memory, 1-day TTL).
    Supply your own `cache` object to persist across processes.

- Rate-Limiting

    Set `min_interval` (seconds) to throttle outbound Nominatim calls
    and comply with the API fair-use policy.

# SUBROUTINES/METHODS

## new

Construct a new `HTML::OSM` object.

    my $map = HTML::OSM->new(%params);
    my $map = HTML::OSM->new(\%params);

Both method-style (`HTML::OSM->new(...)`) and function-style
(`HTML::OSM::new(...)`) calls are supported.
Calling `$existing_obj->new(%overrides)` performs a shallow clone,
merging `%overrides` onto the existing object's state without re-validating.

### API SPECIFICATION

#### INPUT

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

#### OUTPUT

    { type => object, isa => 'HTML::OSM' }

### MESSAGES

    | Message                                        | Meaning / Resolution                          |
    |------------------------------------------------|-----------------------------------------------|
    | (validation error from Params::Validate::Strict) | A param has the wrong type or is out of range |

### PSEUDOCODE

    1. If $class is neither a package name nor a blessed ref, treat as
       function-style call: prepend $class back onto @_ and use __PACKAGE__.
    2. If $class is a blessed ref (clone call): merge override params onto a
       shallow copy and return immediately, bypassing schema validation.
    3. Validate all supplied args against the declared schema.
    4. Merge config-file settings via Object::Configure.
    5. Resolve the cache: caller-supplied object, or in-memory CHI instance.
    6. Bless and return with Readonly CDN constants as defaults.

## add\_marker

Add a point marker to the map.

    $map->add_marker([51.5074, -0.1278], html => 'London');
    $map->add_marker('Paris, France',    html => 'Paris');
    $map->add_marker($geo_coder_result);

Returns 1 on success, 0 if the point cannot be resolved or is out of range.

### API SPECIFICATION

#### INPUT

    point : arrayref [lat, lon] | string address | object with latitude()/longitude()
    html  : string   (optional popup label)
    icon  : string   (optional icon URL)

#### OUTPUT

    { type => integer, enum => [0, 1] }

### MESSAGES

    | Message                              | Meaning / Resolution                        |
    |--------------------------------------|---------------------------------------------|
    | add_marker(): unknown point type     | Point is a ref type with no lat/lon methods |

### EXAMPLES

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

## add\_geojson

Add a GeoJSON layer to the map.

    $map->add_geojson(\%data, style => { color => '#ff0000' }, popup => 'name');

The first argument may be a hashref/arrayref (GeoJSON structure) or a JSON string.
Returns 1 on success.

### API SPECIFICATION

#### INPUT

    data  : hashref | arrayref | string (JSON)
    style : hashref   Leaflet path-style options (color, weight, fillColor, fillOpacity)
    popup : string    Feature property name whose value becomes the popup text

#### OUTPUT

    { type => integer, value => 1 }

### MESSAGES

    | Message              | Meaning / Resolution            |
    |----------------------|---------------------------------|
    | (JSON parse error)   | data string is not valid JSON   |

### EXAMPLES

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

## add\_heatmap

Add a heatmap layer to the map.

    $map->add_heatmap([[51.5, -0.1, 0.8], [51.6, -0.2, 0.5]], radius => 25);

Each point is `[$lat, $lon]` or `[$lat, $lon, $intensity]` (intensity: 0-1).
Requires the Leaflet.heat plugin (`heatmap_js_url`).
Returns 1 on success.

### API SPECIFICATION

#### INPUT

    points : arrayref of ([lat, lon] | [lat, lon, intensity])
    radius : integer  default 25
    blur   : integer  default 15

#### OUTPUT

    { type => integer, value => 1 }

### MESSAGES

    | Message                              | Meaning / Resolution              |
    |--------------------------------------|-----------------------------------|
    | add_heatmap: points must be arrayref | First argument is not an arrayref |

### EXAMPLES

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

## add\_gpx

Add a GPX track to the map from a URL.

    $map->add_gpx('https://example.com/track.gpx');

The map view is auto-fitted to the track bounds after loading.
Requires the leaflet-gpx plugin (`gpx_js_url`).
Returns 1 on success.

### API SPECIFICATION

#### INPUT

    url : string  URL of the GPX file (required)

#### OUTPUT

    { type => integer, value => 1 }

### MESSAGES

    | Message              | Meaning / Resolution       |
    |----------------------|----------------------------|
    | add_gpx: url required | No URL argument supplied  |

### EXAMPLES

    # Add a GPX track from a public URL; the map auto-fits to its bounds
    $map->add_gpx('https://example.com/route.gpx');

    # Multiple tracks on the same map
    $map->add_gpx('https://example.com/morning-run.gpx');
    $map->add_gpx('https://example.com/evening-walk.gpx');

## add\_choropleth

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

### API SPECIFICATION

#### INPUT

    features : arrayref of GeoJSON Feature hashrefs  (required)
    values   : hashref  { feature_property_value => numeric_value }  (required)
    key      : string   feature property to match against values  (default: 'name')
    scale    : arrayref hex-colour strings low-to-high  (default: 5-step YlGnBu)

#### OUTPUT

    { type => integer, value => 1 }

### MESSAGES

    | Message                                  | Meaning / Resolution                   |
    |------------------------------------------|----------------------------------------|
    | add_choropleth: features must be arrayref | First argument is not an arrayref      |
    | add_choropleth: values must be hashref    | Second argument is not a hashref       |

### EXAMPLES

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

## center

Set the map centre to a given point.

    $map->center([40.7128, -74.0060]);
    $map->center($geo_object);
    $map->center('Berlin, Germany');

Returns 1 on success, 0 if the point cannot be resolved.

### API SPECIFICATION

#### INPUT

    point : arrayref [lat, lon] | object with latitude()/longitude() | string address

#### OUTPUT

    { type => integer, enum => [0, 1] }

### MESSAGES

    | Message                                        | Meaning / Resolution                     |
    |------------------------------------------------|------------------------------------------|
    | center(): usage: point => [lat, lon]           | No point argument supplied               |
    | center(): point must have latitude & longitude | Arrayref has != 2 elements               |
    | center(): unknown point type                   | Ref type has no lat/lon methods          |

### EXAMPLES

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

## zoom

Get or set the zoom level (0 = world, 19 = building).

    $map->zoom(10);
    my $z = $map->zoom();

### API SPECIFICATION

#### INPUT

    { zoom => { type => integer, min => 0, max => 19, optional => 1 } }

#### OUTPUT

    { type => integer, min => 0, max => 19 }

### MESSAGES

    | Message                      | Meaning / Resolution                      |
    |------------------------------|-------------------------------------------|
    | (Params::Validate::Strict)   | zoom is not an integer or is out of range |

### EXAMPLES

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

## onload\_render

Render the map and return a two-element list suitable for embedding in HTML.

    my ($head_html, $body_html) = $map->onload_render();

`$head_html` contains the Leaflet CSS, JavaScript, and plugin assets.
Place it inside `<head>...</head>`.

`$body_html` contains the search box, control buttons, map `<div>`,
and the initialisation `<script>`.
Place it inside `<body>...</body>` where the map should appear.

The rendered page provides:

- A Nominatim-powered search box that adds temporary markers.
- A "Clear search markers" button that removes those temporary markers,
leaving static markers (added via `add_marker`) intact.
- A "Reset Map" button that returns the view to the initial centre and zoom.

### API SPECIFICATION

#### INPUT

    (none - uses object state)

#### OUTPUT

    { type => list, elements => [string, string] }

### MESSAGES

    | Message                                          | Meaning / Resolution                        |
    |--------------------------------------------------|---------------------------------------------|
    | No map data provided                             | No markers, GeoJSON, heatmap, GPX, or choropleth added yet |
    | center() must be called when no point markers    | Non-marker-only render needs explicit centre |

### EXAMPLES

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

### PSEUDOCODE

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

# LIMITATIONS

- **Per-marker removal**: Markers added via `add_marker()` cannot yet be
removed individually by clicking them.  The "Clear search markers" button only
removes markers added by the in-page Nominatim search box.
- **Clone validation**: The clone path (`$obj->new(%overrides)`)
bypasses the Params::Validate::Strict schema so subclasses and internal callers
can merge arbitrary state.  Callers are responsible for passing valid overrides.
- **Config-file params unvalidated**: Keys injected by
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) from a config file are not re-run through the schema, so
a malformed config file can introduce invalid types at runtime.
- **Private-method encapsulation**: `_fetch_coordinates`, `_validate`,
and `_js_string` are named with a leading underscore by convention only.
Using [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) in `enforce` mode would make the contract explicit, but
that module is not yet listed as a dependency to avoid breaking white-box tests
in `t/mock.t`.
- **Routing**: Turn-by-turn routing (Leaflet Routing Machine / OSRM) is
explicitly out of scope for this module and will not be added here.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report bugs at [https://github.com/nigelhorne/HTML-OSM/issues](https://github.com/nigelhorne/HTML-OSM/issues).

# SEE ALSO

- [https://wiki.openstreetmap.org/wiki/API](https://wiki.openstreetmap.org/wiki/API)
- [HTML::GoogleMaps::V3](https://metacpan.org/pod/HTML%3A%3AGoogleMaps%3A%3AV3) - the interface this module mirrors for compatibility.
- [https://leafletjs.com/](https://leafletjs.com/)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/HTML-OSM/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

[https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-OSM](https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-OSM)

## TODO

Allow per-marker removal via clicking on a marker.

# FORMAL SPECIFICATION

## new

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

## add\_marker

    AddMarker
      ΔHTML_OSM
      point? : (ℝ x ℝ) ∪ S ∪ GeoObject
      result! : {0, 1}
    -----------------------------------------
      result! = 1 ⟺ point? resolves to (lat, lon) ∈ ValidCoord
      result! = 1 ⟹ coordinates' = coordinates ⌢ ⟨(lat, lon, label, icon)⟩

## add\_geojson

    AddGeoJSON
      ΔHTML_OSM
      data?  : GeoJSONStruct ∪ S
      style? : StyleMap ∪ {∅}
      popup? : S ∪ {∅}
    -----------------------------------------
      geojson' = geojson ⌢ ⟨{data, style, popup}⟩

## add\_heatmap

    AddHeatmap
      ΔHTML_OSM
      points? : iseq (ℝ x ℝ x [0,1])
    -----------------------------------------
      heatmap_layers' = heatmap_layers ⌢ ⟨{points, radius, blur}⟩

## add\_gpx

    AddGPX
      ΔHTML_OSM
      url? : S | url? ≠ ''
    -----------------------------------------
      gpx_tracks' = gpx_tracks ⌢ ⟨url?⟩

## add\_chropleth

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

## center

    Center
      ΔHTML_OSM
      point? : (ℝ x ℝ) ∪ S ∪ GeoObject
      result! : {0, 1}
    -----------------------------------------
      result! = 1 ⟺ point? resolves to (lat, lon) ∈ ValidCoord
      result! = 1 ⟹ center' = (lat, lon)

## zoom

    Zoom
      ΔHTML_OSM
      zoom? : Z ∪ {∅}
      zoom! : Z
    -----------------------------------------
      zoom? ≠ ∅ ⟹ ZOOM_MIN <= zoom? <= ZOOM_MAX
      zoom! = (zoom? ≠ ∅ ∧ zoom' = zoom?) ∨ zoom

## onload\_render

    OnloadRender
      HTML_OSM
      head! : S
      body! : S
    -----------------------------------------
      (#coordinates + #geojson + #heatmap_layers + #gpx_tracks + #choropleth_layers) > 0
      center ≠ ∅  ∨  ∃ valid ∈ coordinates • valid ∈ ValidCoord

# LICENSE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

This program is released under the following licence: GPL2
If you use it,
please let me know.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 357:

    Non-ASCII character seen before =encoding in '—'. Assuming UTF-8
