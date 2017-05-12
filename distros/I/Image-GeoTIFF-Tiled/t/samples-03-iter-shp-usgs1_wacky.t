#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
#use Test::More tests => 2;
use Test::More;

eval { require Geo::ShapeFile; };
if ( $@ ) {
    print "1..1\nok 1\n";
    warn "skipping, Geo::ShapeFile not available\n";
    exit;
}

require './t/test_contains.pl';    # Loads test_contains method
use Image::GeoTIFF::Tiled;

# Wacky shape in usgs1.tif with lots of thin spikes
#   - values: 4,5

my $image     = Image::GeoTIFF::Tiled->new( "./t/samples/usgs1_.tif" );
my $shp       = Geo::ShapeFile->new( './t/samples/usgs1_wacky' );
my $shp_shape = $shp->get_shp_record( 1 );
# my $shape =
# Image::GeoTIFF::Tiled::Shape->load_shape( $image, $shp_shape );

my $iter;

# 1. Filtering
$iter = $image->get_iterator( $shp_shape );
$iter->dump_buffer;
test_contains( $image, $iter, $shp_shape );

# 2. Masking
# - data is 2 pixels buffered on either side
my $buffer    = $iter->buffer;
my $iter_mask = $image->get_iterator_mask( $shp_shape, undef, 2 );
$iter_mask->dump_buffer;
my $mask = $iter_mask->mask;
is( @$buffer,            @$mask - 4,            'masked buffer 2 more rows (on either side)' );
is( @{ $buffer->[ 0 ] }, @{ $mask->[ 0 ] } - 4, 'masked buffer 2 more cols (on either side)' );
for my $r ( 0 .. $iter->rows - 1 ) {
    for my $c ( 0 .. $iter->cols - 1 ) {
        my ( $r_mask, $c_mask ) = ( $r + 2, $c + 2 );
        if ( $mask->[ $r_mask ][ $c_mask ] ) {
            is(
                $iter_mask->get( $r_mask, $c_mask ),
                $iter->get( $r, $c ),
                "($r,$c) mask buffer = non-mask buffer"
              );
        }
        else {
            is( $iter->get( $r, $c ), undef, "($r,$c) buffer empty" );
        }
    }
}

done_testing( 4 + @$buffer * @{ $buffer->[ 0 ] } );
