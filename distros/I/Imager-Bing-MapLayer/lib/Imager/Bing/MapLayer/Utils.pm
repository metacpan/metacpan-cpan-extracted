package Imager::Bing::MapLayer::Utils;

use v5.10.1;

use strict;
use warnings;

use Carp qw/ confess /;
use Const::Exporter;
use Const::Fast;
use List::MoreUtils qw/ minmax /;
use POSIX::2008 qw/ round /;

use version 0.77; our $VERSION = version->declare('v0.1.9');

our @EXPORT;

our @EXPORT_OK = (
    @EXPORT,
    qw/
        width_at_level latlon_to_pixel pixel_to_tile_coords
        tile_coords_to_pixel_origin
        tile_coords_to_quad_key quad_key_to_tile_coords
        bounding_box optimize_points
        get_ground_resolution get_map_scale
        /
);

=head1 NAME

Imager::Bing::MapLayer::Utils - utility functions for map layer modules

=head1 DESCRIPTION

This module contains utility functions for L<Imager::Bing::MapLayer>.

=head1 EXPORTS

By default, none. Constants and functions must be included in the
usage line explicitly.

=head1 CONSTANTS

=head2 C<$TILE_WIDTH>

=head2 C<$TILE_HEIGHT>

The width and height of individual tiles.

=cut

use Const::Exporter default => [
    '$TILE_WIDTH'  => 256,
    '$TILE_HEIGHT' => 256,
];

=head2 C<$MIN_ZOOM_LEVEL>

=head2 C<$MIN_ZOOM_LEVEL>

The minimum and maximum zoom levels supported by these modules.

Note that C<$MAX_ZOOM_LEVEL> can actually be as high as 23, but that
causes bit overflows for calculations on 32-bit integers.  We also

don't want to generate tiles beyond level 18, since the amount of
tiles required is so large that we run out of memory (and we also
don't need it, since Bing switches to a street view mode).

When the tiles are not saved in memory, then we can generate higher
resolutions.  However, Bing doesn't seem to support zoom levels higher
than 19 at this time.

=cut

use Const::Exporter default => [
    '$MIN_ZOOM_LEVEL' => 1,
    '$MAX_ZOOM_LEVEL' => 19,
];

# Local constants used by these functions

const my $PI => 3.1415926535897932;

const my $EARTH_RADIUS    => 6_378_137;    # Earth radius (meters)
const my $METERS_PER_INCH => 0.0254;

=head1 FUNCTIONS

=head2 C<width_at_level>

  my $width = width_at_level( $level );

Returns the width of a zoom level.

=cut

sub width_at_level {
    my ($level) = @_;

    confess
        "invalid level (must be between ${MIN_ZOOM_LEVEL} and ${MAX_ZOOM_LEVEL}"
        if ( ( $level < $MIN_ZOOM_LEVEL ) || ( $level > $MAX_ZOOM_LEVEL ) );

    return 1 << ( $level + 8 );
}

=head2 C<latlon_to_pixel>

  my ($pixel_x, $pixel_y) = latlon_to_pixel( $level, $latitude, $longitude );

Converts latitude and longitude to pixel coodinates on a specific zoom level.

=cut

sub latlon_to_pixel {
    my ( $level, $latitude, $longitude ) = @_;

    my $width = width_at_level($level);

    my $sin_latitude = sin( $latitude * $PI / 180 );

    return map { round($_) } (
        ( ( $longitude + 180 ) / 360 ) * $width,
        (   0.5 - log( ( 1 + $sin_latitude ) / ( 1 - $sin_latitude ) )
                / ( 4 * $PI )
        ) * $width,
    );

}

=head2 C<pixel_to_tile_coords>

  my ($tile_x, $tile_y) = pixel_to_tile_coords( $pixel_x, $pixel_y );

Converts pixel coordinates to map tile coordinates.

=cut

sub pixel_to_tile_coords {
    my ( $pixel_x, $pixel_y ) = @_;
    return map { $_ >> 8 } ( $pixel_x, $pixel_y );
}

=head2 C<tile_coords_to_pixel_origin>

  my ($origin_x, $origin_y) = tile_coords_to_pixel_origin( $tile_x, $tile_y );

Returns the top-left pixel coordinates from tile coordinates.

=cut

sub tile_coords_to_pixel_origin {
    my ( $tile_x, $tile_y ) = @_;
    return map { $_ << 8 } ( $tile_x, $tile_y );
}

=head2 C<tile_coords_to_quad_key>

  my $quad_key = tile_coords_to_quad_key( $level, $tile_x, $tile_y );

Returns the quadrant key ("quad key") for a given tile at a given level.

=cut

sub tile_coords_to_quad_key {
    use integer;

    my ( $level, $tile_x, $tile_y ) = @_;

    my $mask = 1 << ( $level - 1 );
    my $key = '';

    while ($mask) {

        my $digit = 0;

        $digit |= 1 if ( $tile_x & $mask );
        $digit |= 2 if ( $tile_y & $mask );

        $key .= $digit;

        $mask = $mask >> 1;

    }

    return $key;
}

=head2 C<quad_key_to_tile_coords>

    my ($tile_x, $tile_y, $level) = quad_key_to_tile_coords( $quad_key );

Returns the tile coordinates and level from the quad key.

=cut

sub quad_key_to_tile_coords {
    use integer;

    my ($quad_key) = @_;

    state $re = qr/^[0-3]{$MIN_ZOOM_LEVEL,$MAX_ZOOM_LEVEL}$/;

    unless ( $quad_key =~ $re ) {
        confess "invalid quad key";
    }

    my ( $tile_x, $tile_y ) = ( 0, 0 );

    my $level = length($quad_key);    # implicitly checked by regex
    my $mask = 1 << ( $level - 1 );

    # Translate the quad key into a string of digits

    foreach my $digit ( map { $_ - 48 } ( unpack 'c*', $quad_key ) ) {

        $tile_x |= $mask if ( $digit & 1 );
        $tile_y |= $mask if ( $digit & 2 );

        $mask = $mask >> 1;
    }

    return ( $tile_x, $tile_y, $level );
}

=head2 C<get_ground_resolution>

    $meters_per_pixel = get_ground_resolution( $level, $latitude );

This returns the distance on the ground that's represented by a single
pixel.

=cut

sub get_ground_resolution {
    my ( $level, $latitude ) = @_;

    return ( cos( $latitude * $PI / 180 ) * ( 2 * $PI * $EARTH_RADIUS ) )
        / width_at_level($level);

}

=head2 C<get_map_scale>

TODO

=cut

sub get_map_scale {
    my ( $level, $latitude, $screen_dpi ) = @_;

    $screen_dpi //= 96;    # a standard screen dpi

    return get_ground_resolution( $level, $latitude )
        * $screen_dpi / $METERS_PER_INCH;
}

=head2 C<bounding_box>

    my ($left, $top, $right, $bottom) = bounding_box( %args );

This parses the arguments given to L<Imager::Draw> methods to
calculate a bounding box.

=cut

sub bounding_box {
    my (%args) = @_;

    my %points = ( x => [], 'y' => [] );

    if ( my $radius = $args{r} ) {    # radius for arcs and circles

        foreach my $axis (qw/ x y /) {

            push @{ $points{$axis} },
                ( $args{$axis} - $radius, $args{$axis} + $radius );

        }

    } elsif ( my $box = $args{box} ) {

        push @{ $points{x} }, ( $box->[0], $box->[2] );
        push @{ $points{y} }, ( $box->[1], $box->[3] );

    } elsif ( my $list = $args{points} ) {

        foreach my $pt ( @{$list} ) {

            push @{ $points{x} }, $pt->[0];
            push @{ $points{y} }, $pt->[1];

        }

    } else {

        foreach my $axis (qw/ x y /) {

            if ( ref $args{$axis} ) {

                push @{ $points{$axis} }, @{ $args{$axis} };

            } else {

                push @{ $points{$axis} }, $args{$axis}
                    if ( defined $args{$axis} );

            }

            foreach my $alt (qw/ 1 2 min max /) {

                my $arg = $axis . $alt;

                push @{ $points{$axis} }, $args{$arg}
                    if ( defined $args{$arg} );

            }

        }

    }

    my ( $xmin, $xmax ) = minmax( @{ $points{x} } );
    my ( $ymin, $ymax ) = minmax( @{ $points{y} } );

    return ( $xmin, $ymin, $xmax, $ymax );

}

=head2 C<optimize_points>

    my @points2 = @{ optimize_points( \@points ) };

This function takes a reference to a list of points and returns
another reference to a list of points, without adjacent duplicate
points.  This reduces the number of points to plot for complex
polylines on lower zoom levels.

=cut

sub optimize_points {
    my ($points) = @_;

    my $last = $points->[0];

    my @list = ($last);

    my $i = 1;

    while ( my $point = $points->[ $i++ ] ) {

        if ( ( $point->[0] != $last->[0] ) || ( $point->[1] != $last->[1] ) )
        {

            push @list, $point;

            $last = $point;

        }

    }

    return \@list;
}

=head1 SEE ALSO

=over

=item A discussion of the Bing Maps Tile System

L<http://msdn.microsoft.com/en-us/library/bb259689.aspx>

=back

=cut

1;
