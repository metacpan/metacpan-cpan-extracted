#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 8;
use Test::More;

eval { require Geo::ShapeFile; };
if ( $@ ) {
    print "1..1\nok 1\n";
    warn "skipping, Geo::ShapeFile not available\n";
    exit;
}

require './t/test_contains.pl';    # Loads test_contains method
use Image::GeoTIFF::Tiled;

my $image = Image::GeoTIFF::Tiled->new( "./t/samples/usgs2_.tif" );
for my $i ( 1 .. 2 ) {
    my $shp       = Geo::ShapeFile->new( "./t/samples/usgs2_hollow$i" );
    my $shp_shape = $shp->get_shp_record( 1 );
    my $shape =
        Image::GeoTIFF::Tiled::Shape->load_shape( $image, $shp_shape );
    my $iter = $image->get_iterator_shape( $shape );

#    $iter->dump_buffer;

    test_contains( $image, $iter, $shp_shape );

    ok(
        !(
            grep {
                grep { defined and ($_ == 6 || $_ == 1) }
                    @{ $_ }
            } @{ $iter->buffer }
         ),
        'Hollow pixels okay'
      );
    ok(
        !(
            grep {
                grep { defined and $_ != 4 and $_ != 5 }
                    @{ $_ }
            } @{ $iter->buffer }
         ),
        'Shape pixels okay'
      );
} ## end for my $i ( 1 .. 2 )
