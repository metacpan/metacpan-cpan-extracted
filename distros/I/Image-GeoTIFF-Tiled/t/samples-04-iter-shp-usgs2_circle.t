#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9163;
use Test::More;

eval { require Geo::ShapeFile; };
if ( $@ ) {
    print "1..1\nok 1\n";
    warn "skipping, Geo::ShapeFile not available\n";
    exit;
}

require './t/test_contains.pl';    # Loads test_contains method

use Image::GeoTIFF::Tiled;

# Circle in usgs2.tif
#   - surrounds an ovular topographic level ("ring")
#   - values: background = 5, ring = 4

my $image     = Image::GeoTIFF::Tiled->new( "./t/samples/usgs2_.tif" );
my $shp       = Geo::ShapeFile->new( './t/samples/usgs2_circle' );
my $shp_shape = $shp->get_shp_record( 1 );
my $shape =
    Image::GeoTIFF::Tiled::Shape->load_shape( $image, $shp_shape );
my $iter = $image->get_iterator_shape( $shape );
test_contains( $image, $iter, $shp_shape );
my $row   = -1;                   # Incremented, from 0
my $col   = $iter->cols / 2;      # Start from the middle
my $top   = 1;                    # Top of the circle flag
my $saw_4 = 0;
my %count = ( 4 => 0, 5 => 0 );
while ( defined( my $val = $iter->next ) ) {

    if ( $row != $iter->current_row ) {
        # First value in row
        is( ++$row, $iter->current_row, '(circle) current row' );
        # Circle -> previous column before (top) or after (bottom) this column
        if ( $top ) {
            ok( $col >= $iter->current_col, '(circle) current col' );
            $top = 0 if $iter->current_col == 0;
        }
        else {
            ok( $col <= $iter->current_col, '(circle) current_col' );
        }
        $col = $iter->current_col;
        # Values: 4s (ring) and 5s (back)
        is( $val, 5, '(circle) current val' );
        if ( $row > 0 ) {
            ok( $count{ 5 } > $count{ 4 }, '(circle) 5s > 4s' );
            if ( $saw_4 and !$top and !$count{ 4 } ) {
                $saw_4 = 0;
            }
            elsif ( !$top and !$saw_4 ) {
                ok( !$count{ 4 }, '(circle) didnt see ring at bottom' );
            }
            elsif ( !$top or $saw_4 ) {
                ok( $count{ 4 }, '(circle) saw ring' );
            }
        }
        %count = ( 4 => 0, 5 => 0 );
    }
    else {
        ok( $val == 4 || $val == 5, '(circle) current val' );
        $saw_4 = 1 if ( $val == 4 );
    }
    $count{ $val }++;
} ## end while ( defined( my $val ...))
# is( $row + 1, $iter->rows, '(circle) total number of rows' );

