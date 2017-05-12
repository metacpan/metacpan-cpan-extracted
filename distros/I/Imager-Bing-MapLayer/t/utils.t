#!/usr/bin/env perl

# Note: we do not use Test::Most here because there is a conflict with
# Test::Deep's 'all' and List::MoreUtils's 'all'.

use Test::Most;
use Test::Exception;
use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use List::MoreUtils ();

use aliased
    'Imager::Bing::MapLayer::Utils' => 'Utils',
    qw/
    $MIN_ZOOM_LEVEL $MAX_ZOOM_LEVEL width_at_level latlon_to_pixel
    pixel_to_tile_coords tile_coords_to_pixel_origin
    tile_coords_to_quad_key quad_key_to_tile_coords
    /;

ok( $MIN_ZOOM_LEVEL >= 1,              "MIN_ZOOM_LEVEL" );
ok( $MAX_ZOOM_LEVEL <= 23,             "MAX_ZOOM_LEVEL" );
ok( $MIN_ZOOM_LEVEL < $MAX_ZOOM_LEVEL, "MIN_ZOOM_LEVEL < MAX_ZOOM_LEVEL" );

dies_ok {
    width_at_level( $MIN_ZOOM_LEVEL - 1 );
}
"width_at_level (too low)";

dies_ok {
    width_at_level( $MAX_ZOOM_LEVEL + 1 );
}
"width_at_level (too high)";

foreach my $level ( $MIN_ZOOM_LEVEL .. $MAX_ZOOM_LEVEL ) {

    lives_ok {

        my $width = width_at_level($level);
        is( $width & 0xff, 0, "width_at_level is power of 2**8" );

        my @latlon = ( 51.5171, 0.1062 );    # London

        ok( my @pixel = latlon_to_pixel( $level, @latlon ),
            "latlon_to_pixel" );

        ok( (   List::MoreUtils::all { ( $_ >= 0 ) && ( $_ < $width ) }
                @pixel
            ),
            "pixels within width"
        ) or diag( explain \@pixel );

        ok( my @tile = pixel_to_tile_coords(@pixel), "pixel_to_tile_coords" );

        ok( my @origin = tile_coords_to_pixel_origin(@tile),
            "tile_to_pixel_origin" );

        {
            no warnings 'once';

            ok( (   List::MoreUtils::all {$_} (
                        List::MoreUtils::pairwise { $a <= $b } @origin,
                        @pixel
                    )
                ),
                "origin of pixel"
            );

        }

        ok( my $key = tile_coords_to_quad_key( $level, @tile ),
            "tile_coords_to_quad_key" );
        like( $key, qr/^[0-3]{1,23}$/, "well-formed quad key" );
        is( length($key), $level, "length of key" );

        ok( my @check = quad_key_to_tile_coords($key),
            "quad_key_to_tile_coords" );

        is_deeply(
            \@check,
            [ @tile, $level ],
            "quad_key_to_tile_coords(tile_coords_to_quad_key(x)) = x"
        );

    }
    "lives ok";

}

done_testing;

