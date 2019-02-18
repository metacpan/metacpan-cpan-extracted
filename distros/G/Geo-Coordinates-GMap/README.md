# NAME

Geo::Coordinates::GMap - Routines for converting decimal lat/lon to Google
Map tiles, and back again.

# SYNOPSIS

    use Geo::Coordinates::GMap;
    my ($tile_x, $tile_y) = coord_to_gmap_tile( $lat, $lon, $zoom );
    my ($new_tile_x, $new_tile_y) = zoom_gmap_tile( $tile_x, $tile_y, $old_zoom, $new_zoom );
    my ($x, $y) = gmap_tile_xy( $tile_x, $tile_y, $scale );

# DESCRIPTION

While working on the mapping tools on toxicrisk.com I came to the conclusion
that we were dealing with too much data to make everything a GMarker, even
when using the marker manager.

So, I needed to generate static map tile images.  But, to do this, I needed a
way to convert my decimal lat/lon points in to tile numbers, and the pixel
values on those tiles.

This module makes this process simple and accurate.

# FUNCTIONS

## coord\_to\_gmap\_tile

    my ($tile_x, $tile_y) = coord_to_gmap_tile( $lat, $lon, $zoom );

Given a decimal latitude and longitude, and a Google Maps zoom level (0 being farthest away
and 20 being the closest that I'm aware of that you can get), this function will return the
GMap tile location as a fractional x and y coordinate.

## zoom\_gmap\_tile

    my ($new_tile_x, $new_tile_y) = zoom_gmap_tile( $tile_x, $tile_y, $old_zoom, $new_zoom );

Converts fractional tile coordinates, as created by coord\_to\_gmap\_tile(), from one
zoom level to another.

## gmap\_tile\_xy

    my ($x, $y) = gmap_tile_xy( $tile_x, $tile_y, $scale );

Given a tile's x and y coordinate as provided by coord\_to\_gmap\_tile(), this function
will return the pixel location within the tile.

The `$scale` argument may be supplied which can be used to produce high-res tiles.
At this time Google states that the scale can be `1`, `2`, or `4` (only Google
Maps API for Work customers can use `4` with the Google Maps API).  If not specified
the scale will default to `1`.

# TODO

- Implement a routine to convert tile coordinates back in to lat/lon decimal
coordinates.

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
