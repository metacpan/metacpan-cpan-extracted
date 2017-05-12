#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::More;

eval { require Geo::ShapeFile; };
if ( $@ ) {
    print "1..1\nok 1\n";
    warn "skipping, Geo::ShapeFile not available\n";
    exit;
}
eval { require Geo::Proj4; };
if ( $@ ) {
    print "1..1\nok 1\n";
    warn "skipping, Geo::Proj4 not available\n";
    exit;
}

require './t/test_contains.pl';    # Loads test_contains method
use Image::GeoTIFF::Tiled;

#  Polygon in usgs1.tif that needs to be projected
#   - values: 4,5

my $image = Image::GeoTIFF::Tiled->new( "./t/samples/usgs1_.tif" );
my $proj  = Geo::Proj4->new( "+proj=utm +zone=17 +ellps=WGS84 +units=m" )
    or die "parameter error: " . Geo::Proj4->error . "\n";

my $shp       = Geo::ShapeFile->new( './t/samples/usgs1_poly' );
my $shp_shape = $shp->get_shp_record( 1 );
my $shape =
    Image::GeoTIFF::Tiled::Shape->load_shape( $image, $shp_shape, $proj );
my $iter = $image->get_iterator( $shape );

# $iter->dump_buffer;     die;

$SIG{ __WARN__ } = sub {
    # Known diagreement(s) with Geo::ShapeFile::Shape->contains_point
    local $_ = $_[0];
    warn @_
        unless /-299935.31,1866374.55/
        # unless /-78.2019736193844,41.05929317151/
            # or /-78.207182275451,41.058771218435/;
};
test_contains( $image, $iter, $shp_shape, $proj );
