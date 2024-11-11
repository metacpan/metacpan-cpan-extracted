# File: lib/Geo/Leaflet.pm

## NAME

Geo::Leaflet - Generates a Leaflet JavaScript map web page

## SYNOPSIS

    use Geo::Leaflet;
    my $map = Geo::Leaflet->new;
    print $map->html;

## DESCRIPTION

This package builds a [Leaflet JavaScript](https://leafletjs.com/) map web page.

## CONSTRUCTORS

### new

Returns a map object

    my $map = Geo::Leaflet->new(
                                id     => "map",
                                center => [$lat, $lon],
                                zoom   => 13,
                               );

## MAP PROPERTIES

### id

Sets and returns the html id of the map.

Default: "map"

### center

Sets and returns the center of the map.

    $map->center([$lat, $lon]);
    my $center = $map->center;

Default: \[38.2, -97.2\]

### zoom

Sets and returns the zoom of the map.

    $map->zoom(4.5);
    my $zoom = $map->zoom;

Default: 4.5

### setView

Sets the center and zoom of the map and returns the map object (i.e., matches leaflet.js interface).

    $map->setView([51.505, -0.09], 13);

### width

Sets and returns the pixel width of the map.

    $map->width(600);
    my $width = $map->width;

Default: 600

### height

Sets and returns the pixel height of the map.

    $map->height(600);
    my $height = $map->height;

Default: 400

## HTML PROPERTIES

### title

Sets and returns the HTML title.

Default: "Leaflet Map"

## TILE LAYER CONSTRUCTOR

### tileLayer

Creates and returns a tileLayer object which is added to the map.

    $map->tileLayer(
                    url     => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    options => {
                      maxZoom     => 19,
                      attribution => '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                    },
                   );

    Default: OpenStreetMaps

See: [https://leafletjs.com/reference.html#tilelayer](https://leafletjs.com/reference.html#tilelayer)

## ICON CONSTRUCTOR

### icon

    my $icon = $map->icon(
                          name    => "my_icon", #must be a valid JavaScript variable name
                          options => {
                                      iconUrl      => "my-icon.png",
                                      iconSize     => [38, 95],
                                      iconAnchor   => [22, 94],
                                      popupAnchor  => [-3, -76],
                                      shadowUrl    => "my-icon-shadow.png",
                                      shadowSize   => [68, 95],
                                      shadowAnchor => [22, 94],
                                     }
                         );

See: [https://leafletjs.com/reference.html#icon](https://leafletjs.com/reference.html#icon)

## MAP OBJECT CONSTRUCTORS

### marker

Adds a marker object to the map and returns a reference to the marker object.

    $map->marker(lat=>$lat, lon=>$lon);

See: [https://leafletjs.com/reference.html#marker](https://leafletjs.com/reference.html#marker)

### polyline

Adds a polyline object to the map and returns a reference to the polyline object.

    my $latlngs = [[$lat, $lon], ...]
    $map->polyline(coordinates=>$latlngs, options=>{});

See: [https://leafletjs.com/reference.html#polyline](https://leafletjs.com/reference.html#polyline)

### polygon

Adds a polygon object to the map and returns a reference to the polygon object.

    my $latlngs = [[$lat, $lon], ...]
    $map->polygon(coordinates=>$latlngs, options=>{});

See: [https://leafletjs.com/reference.html#polygon](https://leafletjs.com/reference.html#polygon)

### rectangle

Adds a rectangle object to the map and returns a reference to the rectangle object.

    $map->rectangle(llat       => $llat,
                    llon       => $llon,
                    ulat       => $ulat,
                    ulon       => $ulon,
                    options => {});

See: [https://leafletjs.com/reference.html#rectangle](https://leafletjs.com/reference.html#rectangle)

### circle

Adds a circle object to the map and returns a reference to the circle object.

    $map->circle(lat=>$lat, lon=>$lon, radius=>$radius, options=>{});

See: [https://leafletjs.com/reference.html#circle](https://leafletjs.com/reference.html#circle)

## METHODS

### html

### html\_head\_link

### html\_head\_script

### html\_head\_style

### html\_body\_div

### html\_body\_script

### html\_body\_script\_map

### html\_body\_script\_contents

## OBJECT ACCESSORS

### HTML

Returns an [HTML:Tiny](HTML:Tiny) object to generate HTML.

### JSON

Returns a [JSON::XS](https://metacpan.org/pod/JSON::XS) object to generate JSON.

## SEE ALSO

[Geo::Google::StaticMaps::V2](https://metacpan.org/pod/Geo::Google::StaticMaps::V2)
https://leafletjs.com/

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

# File: lib/Geo/Leaflet/tileLayer.pm

## NAME

Geo::Leaflet::tileLayer - Leaflet tileLayer Object

## SYNOPSIS

    use Geo::Leaflet;
    my $map       = Geo::Leaflet->new;
    my $tileLayer = $map->tileLayer(
                                    url     => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    options => {
                                      maxZoom     => 19,
                                      attribution => '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                                    }
                                   );

## DESCRIPTION

This package constructs a Leaflet tileLayer object for use on a [Geo::Leaflet](https://metacpan.org/pod/Geo::Leaflet) map.

## CONSTRUCTORS

### new

Returns a tileLayer object

### osm

Returns the default OpenStreetMaps.org tileLayer.

    my $tileLayer = Geo::Leaflet::tileLayer->osm;

## PROPERTIES

### url

## METHODS

### stringify

## SEE ALSO

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

# File: lib/Geo/Leaflet/polyline.pm

## NAME

Geo::Leaflet::polyline - Leaflet polyline object

## SYNOPSIS

    use Geo::Leaflet;
    my $map      = Geo::Leaflet->new;
    my $polyline = $map->polyline(
                                coordinates => [[$lat, $lon], ...]
                                options     => {},
                               );

## DESCRIPTION

This package constructs a Leaflet polyline object for use on a [Geo::Leaflet](https://metacpan.org/pod/Geo::Leaflet) map.

## PROPERTIES

### coordinates

### options

### popup

## METHODS

### stringify

## SEE ALSO

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

# File: lib/Geo/Leaflet/polygon.pm

## NAME

Geo::Leaflet::polygon - Leaflet polygon object

## SYNOPSIS

    use Geo::Leaflet;
    my $map     = Geo::Leaflet->new;
    my $polygon = $map->polygon(
                                coordinates => [[$lat, $lon], ...]
                                options     => {},
                               );

## DESCRIPTION

This package constructs a Leaflet polygon object for use on a [Geo::Leaflet](https://metacpan.org/pod/Geo::Leaflet) map.

## PROPERTIES

### coordinates

### options

### popup

## METHODS

### stringify

## SEE ALSO

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

# File: lib/Geo/Leaflet/rectangle.pm

## NAME

Geo::Leaflet::rectangle - Leaflet rectangle object

## SYNOPSIS

    use Geo::Leaflet;
    my $map       = Geo::Leaflet->new;
    my $rectangle = $map->rectangle(
                                    llat    => $llat,
                                    llon    => $llon,
                                    ulat    => $ulat,
                                    ulon    => $ulon,
                                    options => {},
                                   );

## DESCRIPTION

This package constructs a Leaflet rectangle object for use on a [Geo::Leaflet](https://metacpan.org/pod/Geo::Leaflet) map.

## PROPERTIES

### llat

### llon

### ulat

### ulon

### options

### popup

## METHODS

### stringify

## SEE ALSO

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

# File: lib/Geo/Leaflet/circle.pm

## NAME

Geo::Leaflet::circle - Leaflet circle object

## SYNOPSIS

    use Geo::Leaflet;
    my $map    = Geo::Leaflet->new;
    my $circle = $map->circle(
                              lat     => $lat,
                              lon     => $lon,
                              radius  => $radius,
                              options => {},
                             );

## DESCRIPTION

This package constructs a Leaflet circle object for use on a [Geo::Leaflet](https://metacpan.org/pod/Geo::Leaflet) map.

## PROPERTIES

### lat

### lon

### radius

### options

## METHODS

### stringify

## SEE ALSO

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

# File: lib/Geo/Leaflet/marker.pm

## NAME

Geo::Leaflet::marker - Leaflet marker object

## SYNOPSIS

    use Geo::Leaflet;
    my $map    = Geo::Leaflet->new;
    my $marker = $map->marker(
                              lat => $lat,
                              lon => $lon,
                             );

## DESCRIPTION

This package constructs a Leaflet marker object for use on a [Geo::Leaflet](https://metacpan.org/pod/Geo::Leaflet) map.

## PROPERTIES

### lat

### lon

### options

### popup

## METHODS

### stringify

## SEE ALSO

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

# File: lib/Geo/Leaflet/icon.pm

## NAME

Geo::Leaflet::icon - Leaflet icon object

## SYNOPSIS

    use Geo::Leaflet;
    my $map = Geo::Leaflet->new;

## DESCRIPTION

This package constructs a Leaflet icon object for use in a [Geo::Leaflet::marker](https://metacpan.org/pod/Geo::Leaflet::marker) object.

## CONSTRUCTORS

### new

## PROPERTIES

### name

### options

## METHODS

### stringify

### JSON

## SEE ALSO

## AUTHOR

Michael R. Davis

## COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

