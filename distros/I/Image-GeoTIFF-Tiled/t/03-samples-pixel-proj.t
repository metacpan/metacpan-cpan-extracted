#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 22;
use Image::GeoTIFF::Tiled;

# Test projected <-> pixel translations
my %exp = (
    # Found using listgeo utility
    './t/samples/usgs1_.tif' => {
        # upper_left => [ '730232.510', 4557035.327 ],
        # lower_left => [ '730232.510', 4540490.783 ],
        # upper_right => [ 742478.155, 4557035.327 ],
        # lower_right => [ 742478.155, 4540490.783 ],
        # center => [ 736355.333, 4548763.055 ]
        upper_left  => [ 731284.056, 4551008.763 ],
        lower_left  => [ 731284.056, 4547412.123 ],
        upper_right => [ 735458.597, 4551008.763 ],
        lower_right => [ 735458.597, 4547412.123 ],
        center      => [ 733371.326, 4549210.443 ]
    },
    './t/samples/usgs2_.tif' => {
        # upper_left  => [ 698753.305, 4556059.506 ],
        # lower_left  => [ 698753.305, 4539568.607 ],
        # upper_right => [ 710925.798, 4556059.506 ],
        # lower_right => [ 710925.798, 4539568.607 ],
        # center      => [ 704839.551, 4547814.057 ]
        upper_left  => [ 705242.075, 4551603.806 ],
        lower_left  => [ 705242.075, 4547714.558 ],
        upper_right => [ 709757.992, 4551603.806 ],
        lower_right => [ 709757.992, 4547714.558 ],
        center      => [ 707500.034, 4549659.182 ]
    },
);

for my $tiff ( keys %exp ) {
    my $image  = Image::GeoTIFF::Tiled->new( $tiff );
    my $w      = $image->width;
    my $l      = $image->length;
    my %lookup = (
        upper_left  => [ 0,      0 ],
        upper_right => [ $w,     0 ],
        lower_right => [ $w,     $l ],
        lower_left  => [ 0,      $l ],
        center      => [ $w / 2, $l / 2 ]
    );
    my @corners;
    for my $loc ( qw/ upper_left upper_right lower_right lower_left center/ ) {
        my $coord = [ map sprintf( "%.1f", $_ ), @{ $lookup{ $loc } } ];
        # Project
        my $got = [ map sprintf( "%.3f", $_ ), $image->pix2proj( @$coord ) ];
        is_deeply( $got, $exp{ $tiff }{ $loc }, "$tiff: $loc projection" );

        push @corners, $got unless $loc eq 'center';

        # Back to pixels
        $got =
            [ map { my $n = sprintf( "%.1f", $_ ); $n != 0 ? $n : '0.0' }
                $image->proj2pix( @$got ) ];
        is_deeply( $got, $coord, "$tiff: $loc pixels" );
    }
    # Test corners method
    my @got_corners = map [ map sprintf( "%.3f", $_ ), @$_ ], $image->corners();
    # warn "@$_\n" for @got_corners;
    is_deeply( \@got_corners, \@corners, "$tiff: corners" );
} ## end for my $tiff ( keys %exp)
