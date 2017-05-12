#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
use Image::GeoTIFF::Tiled;

for my $tiff ( <./t/samples/usgs*.tif> ) {
    my $image = Image::GeoTIFF::Tiled->new( $tiff );
    my $tile  = $image->get_tile( 0 );
    # $image->dump_tile(0); die;
    my $ok = 1;
    for my $v ( @$tile ) {
        unless ( grep $v == $_, qw/ 0 1 4 5 12 / ) {
            $ok = 0;
            print "Bad vaues: $v\n";
        }
    }
    ok( $ok, 'First tile' );

    my @test = ( [ $tile ] );
    $tile = $image->get_tiles( 0, 0 );
    is_deeply( $tile, \@test, '3D Tile data' );

    my $tile_no = 122;
    my ( $ul, $ur, $bl, $br ) = (
        $tile_no,
        $tile_no + 1,
        $tile_no + $image->tile_step,
        $tile_no + 1 + $image->tile_step
    );
#    print "Tiles: $ul, $ur, $bl, $br\n";
    my @tiles = (
        [ $image->get_tile( $ul ), $image->get_tile( $ur ) ],
        [ $image->get_tile( $bl ), $image->get_tile( $br ) ]
    );
    $tile = $image->get_tiles( $ul, $br );
    is_deeply( $tile, \@tiles, '3D Tile data' );
} ## end for my $tiff ( <./t/samples/usgs*.tif>)

sub _round {
    my $aref = shift;
    for my $r ( @$aref ) {
        for my $t ( @$r ) {
            for ( 0 .. @$t - 1 ) {
                $t->[ $_ ] = sprintf( "%.6f", $t->[ $_ ] );
            }
        }
    }
}
