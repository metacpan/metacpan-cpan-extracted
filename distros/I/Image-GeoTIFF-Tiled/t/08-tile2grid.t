#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Indent = 0;
use Test::More tests => 139;
use Image::GeoTIFF::Tiled;

my $tif = Image::GeoTIFF::Tiled->new( './t/samples/usgs1_.tif' );
# $tif->print_meta;

my $tile0 = $tif->get_tile( 0 );
my $mat = $tif->tile2grid( $tile0 );
print Dumper ( $tile0 ), "\n";
print Dumper ( $mat ),   "\n";
for my $r ( 0 .. @$mat - 1 ) {
    my $row    = $mat->[ $r ];
    my $across = @$row;
    my $i      = $r * $across;
    is( $across, $tif->tile_width, "across ($across)" );
    die
        unless is_deeply(
                $row,
                [ @$tile0[ $i .. $i + $across - 1 ] ],
                "tile2grid at $i"
        );
}
# print Dumper ($tile0), "\n";
# print Dumper ($mat),"\n";

my $tiles = $tif->get_tiles( 0, $tif->tiles_across + 1 );
is( scalar @$tiles,            2, 'tiles down' );
is( scalar @{ $tiles->[ 0 ] }, 2, 'tiles across' );
is(
    scalar @{ $tiles->[ 0 ][ 0 ] },
    $tif->tile_width * $tif->tile_length,
    'tile size'
  );
$mat = $tif->tiles2grid( $tiles );
is( scalar @$mat,            64 * 2, 'mat rows' );
is( scalar @{ $mat->[ 0 ] }, 64 * 2, 'mat cols' );

# Test extraction against grid methods
is_deeply(
    $tif->tile2grid( 0 ),
    $tif->extract_grid( 0, 0, 63, 63 ),
    'tile2grid <-> extract_grid'
);

is_deeply(
    $tif->tiles2grid( 1, 1 ),
    $tif->extract_grid( 64, 0, 127, 63 ),
    'tile2grid <-> extract_grid'
);

is_deeply(
    $tif->tiles2grid( 0, 1 ),
    $tif->extract_grid( 0, 0, 127, 63 ),
    'tiles2grid <-> extract_grid'
);

is_deeply(
    $tif->tiles2grid( 0, $tif->tiles_across ),
    $tif->extract_grid( 0, 0, 63, 127 ),
    'tiles2grid <-> extract_grid'
);

is_deeply(
    $tif->tiles2grid( 1, $tif->tiles_across + 2 ),
    $tif->extract_grid( 64, 0, 64 * 3 - 1, 127 ),
    'tiles2grid <-> extract_grid'
);

# Test histograms
my ( %ht, %hm );
for ( @$tiles ) {

    for ( @$_ ) {
        $ht{ $_ }++ for @$_;
    }
}
for ( @$mat ) {
    $hm{ $_ }++ for @$_;
}
is_deeply( \%hm, \%ht, '3D tiles -> 2D matrix histogram' );
