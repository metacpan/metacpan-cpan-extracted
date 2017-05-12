use strict;
use warnings;
our $VERSION = '0.04';
package Geo::GoogleMaps::OffsetCenter;
# ABSTRACT: Offset a Lat/Long in Google Maps


use Params::Validate;
use Math::Trig qw/ pi /;
use Regexp::Common;
use Exporter::Easy (
    OK => [ qw/ offset_center_by_pixel / ],
);

use constant RADIUS_OF_EARTH => 6_378_100;


sub offset_center_by_pixel {
    validate_pos(
        @_,
        { regex => qr/$RE{num}{real}/, optional => 0 }, # latitude
        { regex => qr/$RE{num}{real}/, optional => 0 }, # longitude
        { regex => qr/$RE{num}{int}/,  optional => 0 }, # width of the whole image
        { regex => qr/$RE{num}{int}/,  optional => 0 }, # height of the whole image
        { regex => qr/$RE{num}{int}/,  optional => 0 }, # x coordinate of where it should be; x_final
        { regex => qr/$RE{num}{int}/,  optional => 0 }, # y coordinate of where it should be; y_final
        { regex => qr/$RE{num}{int}/,  optional => 0 }, # zoom level
    );

    my(
        $latitude_geo_entity,
        $longitude_geo_entity,
        $width_total,
        $height_total,
        $x_final,
        $y_final,
        $zoom_level,
    ) = @_;

    # important for both vertical and horizontal offset
    my $number_of_pixels = 256 * 2**$zoom_level;
    my $x_initial = int( $width_total / 2 );
    my $y_initial = int( $height_total / 2 );

    # important for vertical offset
    my $meters_per_pixel_vertical  = ( pi * RADIUS_OF_EARTH ) / $number_of_pixels; # pi * r = length of longitude
    my $meters_per_degree_vertical = ( pi * RADIUS_OF_EARTH ) / 180;

    # important for horizontal offset
    my $meters_per_pixel_horizontal  = ( 2 * pi * RADIUS_OF_EARTH ) / $number_of_pixels;
    my $meters_per_degree_horizontal = ( 2 * pi * RADIUS_OF_EARTH ) / 360;

    #####################
    # horizontal offset #
    #####################

    my $horizontal_offset_in_degrees;
    {
        my $pixels_offset = -1 * ($x_final - $x_initial);

        # find the number of meters we need to move
        my $meters_offset = $pixels_offset * $meters_per_pixel_horizontal;

        # now find the number of degrees we need to move
        $horizontal_offset_in_degrees = $meters_offset / $meters_per_degree_horizontal;
    }

    ###################
    # vertical offset #
    ###################

    my $vertical_offset_in_degrees;
    {
        my $pixels_offset = -1 * ($y_final - $y_initial);

        # find the number of meters we need to move
        my $meters_offset = $pixels_offset * $meters_per_pixel_vertical;

        # now find the number of degrees we need to move
        $vertical_offset_in_degrees = $meters_offset / $meters_per_degree_vertical;
    }

    $latitude_geo_entity  += $vertical_offset_in_degrees;
    $longitude_geo_entity += $horizontal_offset_in_degrees;

    return {
        latitude  => sprintf( '%.6f', $latitude_geo_entity ),
        longitude => sprintf( '%.6f', $longitude_geo_entity ),
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::GoogleMaps::OffsetCenter - Offset a Lat/Long in Google Maps

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Geo::GoogleMaps::OffsetCenter qw/ offset_center_by_pixel /;

 my $new_lat_long = offset_center_by_pixel(
    52.3728, # latitude
    4.8930,  # longitude
    800,     # width
    400,     # height
    622,     # desired x-coordinate
    70,      # desired y-coordinate
    16,      # Google Maps zoom level
 );

=head1 DESCRIPTION

Consider the following situation:

 A
 +-----------------------------------------------------+
 | +-----------------------+B                          |
 | |                       |                           |
 | |  Lorem ipsum          |                           |
 | |                       |           Map Area        |
 | |                       |                           |
 | |                       |                           |
 | |                       |                           |
 | +-----------------------+                           |
 +-----------------------------------------------------+

Box A is your full map area, and box B is an overlay containing text. Box B is
considered the occlusion in this case.

This means the effective map area is the region to the right, even though map
tiles need to be rendered below box A. There are many display situations where
this might be necessary:

=over 4

=item *

The overlay is translucent, and map tiles are visible beneath it.

=item *

The overlay does not touch the edges of the map it overlays, and so it needs to
be framed by map tiles.

=back

This module will allow you to do an offset of a given latitude/longitude under
different circumstances.

There are 2 prevailing techniques in this module. By specifying a left-bound
occlusion, and by specifying pixel coordinated on your image.

=head1 NAME

Geo::GoogleMaps::OffsetCenter - Offset a Lat/Long to account for an occlusion over your map area

=head1 VERSION

 version 0.03

=head1 METHODS

=over 4

=item I<offset_center_by_pixel>

=over 8

=item 1. Latitude

A valid latitude of your geo entity, basically a floating point number.

=item 2. Longitude

A valid longitude of your geo entity, same as above.

=item 3. Total Width of the Map Area

The total width of the map you want rendered. This includes any occluded areas,
although it is partially or wholly occluded, you will need a rendering of a map
in this area.

=item 4. Total Height of the Map Area

The total height of the map you want rendered, include possibly occluded areas,
same as above. This function allows vertical offset.

=item 5. Desired X Coordinate

Consider your image as a cartesian coordinate space.

   y                                            
   ^                                            
   |                                            
   |                                            
   |                                            
   |                       . (x,y)              
   |                                            
   +--------------------------------------> x   

x represents width, and y represents height. Origined at the bottom-left of
your image, this is the x coordinate of where you need your lat/long to be
rendered on the image.

=item 6. Desired Y Coordinate

Same as above, except the y coordinate on the image.

=item 7. Google Maps Zoom Level

A Google Maps zoom-level, basically 0 .. 21.

See L<Google Maps Documentation|https://developers.google.com/maps/documentation/staticmaps/#Zoomlevels>.

=back

=back

=head1 ACKNOWLEDGEMENT

This module was originally developed for use at Booking.com, and was
genericized and published on CPAN with their permission, for which the author
would like to express his gratitude.

=head1 AUTHOR

Iftekharul Haque <iftekhar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Iftekharul Haque.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
