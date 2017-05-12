#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

eval { require Image::ExifTool; };
if ( $@ ) {
    print "1..1\nok 1\n";
    warn "skipping, Image::ExifTool not available\n";
    exit;
}

use Image::GeoTIFF::Tiled;

my @images = <./t/samples/*.tif>;
plan tests => 10 * @images;

for my $tiff ( @images ) {
    print "$tiff\n";
    my $exif = Image::ExifTool->new();
    $exif->ExtractInfo( $tiff )
        or die $exif->GetValue( 'Error' );
    my $image = Image::GeoTIFF::Tiled->new( $tiff );
    is( $image->file,   $tiff,                            'Image file path' );
    is( $image->length, $exif->GetValue( 'ImageHeight' ), 'image length' );
    is( $image->width,  $exif->GetValue( 'ImageWidth' ),  'image width' );
    is( $image->tile_length, $exif->GetValue( 'TileLength' ), 'tile length' );
    is( $image->tile_width,  $exif->GetValue( 'TileWidth' ),  'tile width' );
    is( $image->tile_area,
        $exif->GetValue( 'TileLength' ) * $exif->GetValue( 'TileWidth' ),
        'tile size' );
    is( $image->tile_size,
        $exif->GetValue( 'TileLength' ) * $exif->GetValue( 'TileWidth' )
        * $exif->GetValue( 'BitsPerSample' ) / 8,
        'tile size' );
    # relies on pix2tile
    is( $image->tile_step, $image->pix2tile( 0, $image->tile_length + 1 ),
        'tile step' );
    is( $image->tile_step, $image->tiles_across, 'tile step = tiles across' );
    is( $image->tiles_total, $image->number_of_tiles,
        'total tiles = # of tiles' );
}
