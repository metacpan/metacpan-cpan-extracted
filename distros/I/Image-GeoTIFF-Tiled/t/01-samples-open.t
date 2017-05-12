#!/usr/bin/perl
use strict;
use warnings;
use Image::GeoTIFF::Tiled;
use Test::More;
my @images = <./t/samples/*.tif>;
plan tests => scalar @images;
for my $tiff (@images) {
#    print "Test image: $tiff\n";
    eval { Image::GeoTIFF::Tiled->new( $tiff ) };
    if ($@) {
        print $@;
    }
    ok( ! $@, "$tiff opened" );
}

