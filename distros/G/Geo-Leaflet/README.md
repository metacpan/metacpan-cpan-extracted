# File: lib/Geo/Leaflet.pm

## NAME

Geo::Leaflet - Generates a Leaflet JavaScript map web page

## SYNOPSIS

    use Geo::Leaflet;
    my $map = Geo::Leaflet->new;
    print $map->html;

## DESCRIPTION

This package generates a [Leaflet JavaScript](https://leafletjs.com/) map web page.

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

Sets and returns the percent or pixel width of the map.

    $map->width('600px');
    $map->width('100%');
    my $width = $map->width;

Default: 100%

### height

Sets and returns the percent or pixel height of the map.

    $map->height('400px');
    $map->height('100%');
    my $height = $map->height;

Default: 100%

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

## ICON CONSTRUCTORS

### icon

Represents an icon to provide when creating a marker.

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

### divIcon

Represents a lightweight icon for markers that uses a simple \`div\` element instead of an image. 

Font Awesome with defaults

    my $icon = $map->divIcon(icon_name => "bicycle");

Font Awesome with tweaks

    my $icon = $map->divIcon(
                             icon_name      => "bicycle",
                             icon_font_size => 22,
                             options => {
                                         iconAnchor => [11,11],
                                        },
                            );

Other CSS options

    my $icon = $map->divIcon(
                          options => {
                                      html  => '<i class="fa fa-map-marker", style="font-size:48px"></i>',
                                      iconAnchor => [13, 44],
                                     }
                         );

See: https://leafletjs.com/reference.html#divicon

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

### html\_head\_links

### html\_head\_script

### html\_head\_style

### html\_body\_div

### html\_body\_script

### html\_body\_script\_map

### html\_body\_script\_contents

## DATA ACCESSORS

### map\_objects

Returns the array reference of map objects to be added to the map

    $map->map_objects($icon);

### icon\_objects

Returns the array reference of icon objects to be added to the map

    $map->icon_objects($icon);

### icon\_sets

Returns the array reference of icon sets to be added to the map

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

# File: lib/Geo/Leaflet/TileLayer.pm

## NAME

Geo::Leaflet::TileLayer - Leaflet tileLayer Object

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

Returns the default OpenStreetMaps.org TileLayer.

    my $tileLayer = Geo::Leaflet::TileLayer->osm;

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

# File: lib/Geo/Leaflet/Polyline.pm

## NAME

Geo::Leaflet::Polyline - Leaflet polyline object

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

# File: lib/Geo/Leaflet/Polygon.pm

## NAME

Geo::Leaflet::Polygon - Leaflet polygon object

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

# File: lib/Geo/Leaflet/Rectangle.pm

## NAME

Geo::Leaflet::Rectangle - Leaflet rectangle object

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

# File: lib/Geo/Leaflet/Circle.pm

## NAME

Geo::Leaflet::Circle - Leaflet circle object

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

# File: lib/Geo/Leaflet/Marker.pm

## NAME

Geo::Leaflet::Marker - Leaflet marker object

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

# File: lib/Geo/Leaflet/Icon.pm

## NAME

Geo::Leaflet::Icon - Leaflet icon object

## SYNOPSIS

    use Geo::Leaflet;
    my $map = Geo::Leaflet->new;

## DESCRIPTION

This package constructs a Leaflet icon object for use in a [Geo::Leaflet::Marker](https://metacpan.org/pod/Geo::Leaflet::Marker) object.

## CONSTRUCTORS

### new

## PROPERTIES

### name

The JavaScript name for the icon object.

Default: iconNNN

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

# File: lib/Geo/Leaflet/DivIcon.pm

## NAME

Geo::Leaflet::DivIcon - Leaflet HTML/CSS icon object

## SYNOPSIS

    use Geo::Leaflet;
    my $map = Geo::Leaflet->new;

## DESCRIPTION

This package constructs a Leaflet divIcon object for use in a [Geo::Leaflet::Marker](https://metacpan.org/pod/Geo::Leaflet::Marker) object.

## CONSTRUCTORS

### new

## PROPERTIES

### name

### icon\_set

    $icon->icon_set('fa'); #Font Awesome v4.7

### icon\_name

    $icon->icon_name('bicycle');

See: https://fontawesome.com/v4/icons/

### icon\_font\_size

    $icon->icon_name(48);

Default: 48

### 

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

