Geo-Leaflet version 0.01
========================

The README is used to introduce the module and provide instructions on
how to install the module, any machine dependencies it may have (for
example C compilers and installed libraries) and any other information
that should be provided before the module is installed.

A README file is required for CPAN modules since CPAN extracts the
README file from a module distribution so that people browsing the
archive can use it get an idea of the modules uses. It is usually a
good idea to provide version information here so that people can
decide whether fixes for the module are worth downloading.

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

DEPENDENCIES

This module requires these other modules and libraries:

  blah blah blah

COPYRIGHT AND LICENCE

Put the correct copyright and licence information here.

Copyright (C) 2024 by Michael R. Davis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


# NAME

Geo::Leaflet - Generates Leaflet web page

# SYNOPSIS

    use Geo::Leaflet;
    my $map = Geo::Leaflet->new;
    print $map->html;

# DESCRIPTION

The package is designed to be able to build a Leaflet map similar to what [Geo::Google::StaticMaps::V2](https://metacpan.org/pod/Geo::Google::StaticMaps::V2) used to be able to provide.

# CONSTRUCTORS

## new

Returns a map object

    my $map = Geo::Leaflet->new(
                                id     => "map",
                                center => [$lat, $lon],
                                zoom   => 13,
                               );

## marker

## setView

    $map->setView([51.505, -0.09], 13);

## center

## zoom

# SEE ALSO

[Geo::Google::StaticMaps::V2](https://metacpan.org/pod/Geo::Google::StaticMaps::V2)
https://leafletjs.com/

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE
# NAME

Geo::Leaflet - Generates Leaflet web page

# SYNOPSIS

    use Geo::Leaflet;
    my $map = Geo::Leaflet->new;
    print $map->html;

# DESCRIPTION

The package is designed to be able to build a Leaflet map similar to what [Geo::Google::StaticMaps::V2](https://metacpan.org/pod/Geo::Google::StaticMaps::V2) used to be able to provide.

# CONSTRUCTORS

## new

Returns a map object

    my $map = Geo::Leaflet->new(
                                id     => "map",
                                center => [$lat, $lon],
                                zoom   => 13,
                               );

# MAP PROPERTIES

## id

Sets and returns the html id of the map.

Default: "map"

## center

Sets and returns the center of the map.

    $map->center([$lat, $lon]);
    my $center = $map->center;

Default: \[38.2, -97.2\]

## zoom

Sets and returns the zoom of the map.

    $map->zoom(4.5);
    my $zoom = $map->zoom;

Default: 4.5

## setView

Sets the center and zoom of the map and returns the map object (i.e., matches leaflet.js interface).

    $map->setView([51.505, -0.09], 13);

## width

Sets and returns the pixel width of the map.

    $map->width(600);
    my $width = $map->width;

Default: 600

## height

Sets and returns the pixel height of the map.

    $map->height(600);
    my $height = $map->height;

Default: 400

# HTML PROPERTIES

## title

Sets and returns the HTML title.

Default: "Leaflet Map"

## objects

# OBJECT CONSTRUCTORS

## tileLayer

Creates and returns a tileLayer object which is added to the map.

    $map->tileLayer(
                    url         => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    maxZoom     => 19,
                    attribution => '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                   );

    Default: OpenStreetMaps

## marker

Adds a marker object to the map and returns a reference to the marker object.

    $map->marker(lat=>$lat, lon=>$lon);

## circle

Adds a circle object to the map and returns a reference to the circle object.

    $map->circle(lat=>$lat, lon=>$lon, radius=>$radius, properties=>{});

## polygon

Adds a polygon object to the map and returns a reference to the polygon object.

    my $latlngs = [[$lat, $lon], ...]
    $map->polygon(coordinates=>$latlngs, properties=>{});

# METHODS

## html

## html\_head\_link

## html\_head\_script

## html\_head\_style

## html\_body\_div

## html\_body\_script

## html\_body\_script\_map

## html\_body\_script\_contents

# OBJECT ACCESSORS

## CGI

Returns a [CGI](https://metacpan.org/pod/CGI) object to generate HTML.

# SEE ALSO

[Geo::Google::StaticMaps::V2](https://metacpan.org/pod/Geo::Google::StaticMaps::V2)
https://leafletjs.com/

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE
