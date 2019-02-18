package Geo::Coordinates::GMap;

$Geo::Coordinates::GMap::VERSION = '0.08';

=head1 NAME

Geo::Coordinates::GMap - Routines for converting decimal lat/lon to Google
Map tiles, and back again.

=head1 SYNOPSIS

    use Geo::Coordinates::GMap;
    my ($tile_x, $tile_y) = coord_to_gmap_tile( $lat, $lon, $zoom );
    my ($new_tile_x, $new_tile_y) = zoom_gmap_tile( $tile_x, $tile_y, $old_zoom, $new_zoom );
    my ($x, $y) = gmap_tile_xy( $tile_x, $tile_y, $scale );

=head1 DESCRIPTION

While working on the mapping tools on toxicrisk.com I came to the conclusion
that we were dealing with too much data to make everything a GMarker, even
when using the marker manager.

So, I needed to generate static map tile images.  But, to do this, I needed a
way to convert my decimal lat/lon points in to tile numbers, and the pixel
values on those tiles.

This module makes this process simple and accurate.

=cut

use strictures 2;
use Math::Trig;

use Exporter qw( import );
our @EXPORT = qw(
    coord_to_gmap_tile
    zoom_gmap_tile
    gmap_tile_xy
);

=head1 FUNCTIONS

=head2 coord_to_gmap_tile

    my ($tile_x, $tile_y) = coord_to_gmap_tile( $lat, $lon, $zoom );

Given a decimal latitude and longitude, and a Google Maps zoom level (0 being farthest away
and 20 being the closest that I'm aware of that you can get), this function will return the
GMap tile location as a fractional x and y coordinate.

=cut

# Inspired by some C# code at:
# http://groups.google.co.in/group/Google-Maps-API/browse_thread/thread/d2103ac29e95696f

sub coord_to_gmap_tile {
    my ($lat, $lon, $zoom) = @_;

    # The C# code did this, but I don't know why, so I'm not going to enable it.
    #return if abs($lat) > 85.0511287798066;

    my $sin_phi = sin( $lat * pi / 180 );

    my $norm_x = $lon / 180;
    my $norm_y = (0.5 * log((1 + $sin_phi) / (1 - $sin_phi))) / pi;

    my $tile_x = (2 ** $zoom) * (($norm_x + 1) / 2);
    my $tile_y = (2 ** $zoom) * ((1 - $norm_y) / 2);

    return(
        $tile_x,
        $tile_y,
    );
}

=head2 zoom_gmap_tile

    my ($new_tile_x, $new_tile_y) = zoom_gmap_tile( $tile_x, $tile_y, $old_zoom, $new_zoom );

Converts fractional tile coordinates, as created by coord_to_gmap_tile(), from one
zoom level to another.

=cut

sub zoom_gmap_tile {
    my ($tile_x, $tile_y, $old_zoom, $new_zoom) = @_;

    if ($new_zoom < $old_zoom) {
        foreach ($new_zoom .. ($old_zoom-1)) {
            $tile_x = $tile_x / 2;
            $tile_y = $tile_y / 2;
        }
    }
    elsif ($new_zoom > $old_zoom) {
        foreach (($old_zoom+1) .. $new_zoom) {
            $tile_x = $tile_x * 2;
            $tile_y = $tile_y * 2;
        }
    }

    return( $tile_x, $tile_y );
}

=head2 gmap_tile_xy

    my ($x, $y) = gmap_tile_xy( $tile_x, $tile_y, $scale );

Given a tile's x and y coordinate as provided by coord_to_gmap_tile(), this function
will return the pixel location within the tile.

The C<$scale> argument may be supplied which can be used to produce high-res tiles.
At this time Google states that the scale can be C<1>, C<2>, or C<4> (only Google
Maps API for Work customers can use C<4> with the Google Maps API).  If not specified
the scale will default to C<1>.

=cut

sub gmap_tile_xy {
    my ($tile_x, $tile_y, $scale) = @_;

    $scale ||= 1;

    return(
        int( (($tile_x - int($tile_x)) * 256 * $scale) + 0.5 ),
        int( (($tile_y - int($tile_y)) * 256 * $scale) + 0.5 ),
    );
}

1;
__END__

=head1 TODO

=over

=item *

Implement a routine to convert tile coordinates back in to lat/lon decimal
coordinates.

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

