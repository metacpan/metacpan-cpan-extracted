# NAME

Geo::OSM::Imager - simplifies plotting onto OpenStreetMap tiles

# SYNOPSIS

    my $g=Geo::OSM::Imager->new(ua => 'MyApplication');
    my $image=$g->init(\@points);
    ...
    my ($x,$y)=$g->latlon2xy($lat,$lon);
    $image->circle(x=>$x,y=>$y,r=>50,color=>$blue);
    ...
    $image->circle($g->latlon2hash($lat,$lon),r=>50,color=>$blue);
    ...
    $image->write(file => 'test.png');

# DESCRIPTION

This module sets up an Imager object made of OpenStreetMap tiles, for
drawing of geographic data.

Beware of over-using OpenStreetMap tile servers, and see the usage
policy at https://operations.osmfoundation.org/policies/tiles/ .

Be hesitant about drawing straight lines over long distances, as map
projections will cause distortion. Over more than a few hundred
metres, the author prefers to break the line into a series of points
and plot individual line segments.

# USAGE

- new()

    Creates a new Geo::OSM::Imager object. Takes an optional hash of
    parameters:

        maxx - maximum X size of the image, in pixels.
        maxy - maximum Y size of the image, in pixels.

    The image will generally be between 50% and 100% of this size.

        margin    - fractional margin around bounding points
        marginlat - fractional latitude margin around bounding point
        marginlon - fractional longitude margin around bounding points

    The fraction of the latitude/longitude span to leave as space around
    the matter to be plotted. With a margin of zero, points will be
    plotted right at the edges of the image. A margin of 1/7 works well,
    and is the default. marginlat and marginlon allow you to define this
    separately for latitude and longitude.

        tileage - minimum age to expire tiles

    The number of seconds after which a tile may be considered "old" and
    re-downloaded. Tileserver usage policy forbids an expiry of less than
    one week (604800s), which is the default.

        tiledir - directory for the tile cache

    The directory in which to store tiles; it must exist.

        tilesize - size of tiles

    The pixel size of each tile. Leave at its default of 256 unless you
    know what you're doing.

        tileurl - base URL for downloading tiles

    The base URL for downloading files. If you are using a local
    tileserver, or a public tileserver other than OpenStreetMap, set it
    here.

        ua - user-agent

    Tileserver usage policy requires a "Valid HTTP User-Agent identifying
    application".

- init()

    Checks bounds and sets up the image. Pass an arrayref of points, each
    of which can be either an arrayref \[lat,lon\] or a hashref including
    lat and lon keys (or "latitude", "long", "longitude").

    These need not be the same points you're going to plot, though that's
    obviously the easiest approach.

    Returns the Imager object.

- image()

    Returns the Imager object.

- zoom()

    Returns the zoom level of the initialised object. See
    [Zoom levels](http://wiki.openstreetmap.org/wiki/Zoom_levels) and
    [Slippy Map Tilenames](http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)
    for more.

- latlon2xy($lat,$lon)

    Given a (latitude, longitude) coordinate pair, returns the (x, y)
    coordinate pair needed to plot onto the Imager object.

- latlon2hash($lat,$lon)

    Given a (latitude, longitude) coordinate pair, returns a list of the
    form ('x', $x, 'y', $y) for use with many Imager plotting functions.

- segment($lat1,$lon1,$lat2,$lon2,$step)

    Given two (latitude, longitude) coordinate pairs and a step value,
    returns an arrayref of (latitude, longitude) coordinate pairs
    interpolating the route on a great circle. This is generally worth
    doing when distances exceed around 100 miles or high precision is
    wanted.

    A positive step value is the length of each segment in metres. A
    negative step value is the number of divisions into which the overall
    line should be split.

# OTHER CONSIDERATIONS

Note that you need not draw directly onto the supplied object: you can
create a new transparent image using the width and height of the one
provided by the module, draw onto that, and copy the results with a
rubthrough or compose command. See [Imager::Transformations](https://metacpan.org/pod/Imager::Transformations) for
more.

# BUGS

Won't work to span +/- 180 degrees longitude.

# LICENSE

Copyright (C) 2017 Roger Bell\_West.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Roger Bell\_West <roger@firedrake.org>

# SEE ALSO

[Imager](https://metacpan.org/pod/Imager)
