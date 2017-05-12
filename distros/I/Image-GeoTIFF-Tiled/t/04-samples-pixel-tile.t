#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 120; 
use Image::GeoTIFF::Tiled;

# Test tile, index functions

for my $tiff (<./t/samples/usgs*.tif>) {
    my $image = Image::GeoTIFF::Tiled->new($tiff);
    my $tw = $image->tile_width;
    my $tl = $image->tile_length;

    my @test = (
        # ($px,$py) <-> (tile,idx)
#        [ -1, 0, 0, 0 ],       # TODO: return undef when outside boundary;
#        TIFFComputeTile not well defined (says it returns valid values but
#        I'm not sure)
        [ 0, 0, 0, 0 ],
        [ 1, 0, 0, 1 ],
        [ 0, 1, 0, $tw ],
        [ 2, 2, 0, $tw * 2 + 2 ],
        [ $tw - 1, 0, 0, $tw - 1 ],
        [ $tw - 1, 2, 0, 2*$tw + $tw - 1 ],
        [ $tw, 0, 1, 0 ],
        [ 0, $tl, $image->tile_step, 0 ],
        [ $tw, $tl, $image->tile_step + 1, 0 ],
        [ $tw - 1, $tl - 1, 0, $tw * $tl - 1 ]
    );

    for ( @test ) {
        my ($px,$py) = ($_->[0],$_->[1]);
        my $t = $image->pix2tile($px,$py);
        is( $t, $_->[2], "($px,$py) tile number: $t" );
        my $i = $image->pix2tileidx($px,$py);
        is( $i, $_->[3], "($px,$py) index into tile: $i" );
        my ($x,$y) = $image->tile2pix( $t, $i );
        is( $x, $px, "x pixel get coordinate of tile ($t) + index ($i)" );
        is( $y, $py, "y pixel get coordinate of tile ($t) + index ($i)" );
        ($x,$y) = (0,0);
        $image->tile2pix_m( $t, $i, $x, $y );
        is( $x, $px, "x pixel get coordinate of tile ($t) + index ($i)" );
        is( $y, $py, "y pixel get coordinate of tile ($t) + index ($i)" );
    }
}
