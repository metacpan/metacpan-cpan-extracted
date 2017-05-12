#!/usr/bin/perl -w
use strict;
use Test::More;

# This line comes from perlport.pod
my $AM_BIG_ENDIAN = unpack( 'h*', pack( 's', 1 ) ) =~ /01/ ? 1 : 0;

# $h must be divisible by 3
my $w = 4;
my $h = 6;
plan tests => 4 + 3 * $w * $h;    # ntests * dimensions

use_ok('Image::Imlib2');

ok( !Image::Imlib2->new_using_data( 16, 16 ), 'no data arg' );
ok( !Image::Imlib2->new_using_data( 16, 16, "0" x 16 ),
    'wrong length data arg' );
ok( Image::Imlib2->new_using_data( 16, 16, "0" x ( 4 * 16 * 16 ) ),
    'right length data arg' );

# Create two images with the same data.
# One is created with an array of packed pixels
# The other has a rectangle filled on it

# The images are three horizontal bands of different color, to test
# that the pixel order is right.

# Note: if any of the colors has a non-255 alpha, then this test fails
# unless the control image also uses new_using_data to clear itself
# first (all pixels to 0,0,0,0).  Reason: new_using_data overwrites the image while
# fill_rectangle blends with (255,0,0,0), giving a different result.

my $null = pack 'CCCC', 0, 0, 0, 0;

# First test has just opaque pixels.  Second has a translucent pixel
for my $test (
    {   blend  => 1,
        pixels => [
            [ 255, 255, 127, 0 ],     #ARGB
            [ 255, 127, 127, 127 ],
            [ 255, 0,   127, 255 ]
        ]
    },

    {   blend  => 1,
        pixels => [
            [ 255, 255, 127, 0 ],     #ARGB
            [ 127, 127, 127, 127 ],
            [ 255, 0,   127, 255 ]
        ]
    },

    {   blend  => 0,
        pixels => [
            [ 255, 255, 127, 0 ],     #ARGB
            [ 127, 127, 127, 127 ],
            [ 255, 0,   127, 255 ]
        ]
    },
    )
{
    Image::Imlib2->will_blend( $test->{blend} );

    my $pixels = $test->{pixels};
    my $alpha  = grep { $_->[0] != 255 } @$pixels;
    my @packed = map { pack 'CCCC', ($AM_BIG_ENDIAN ? @$_ : reverse @$_) } @$pixels;
    my $rect   = ( $packed[0] x ( $w * $h / 3 ) )
        . ( $packed[1] x ( $w * $h / 3 ) )
        . ( $packed[2] x ( $w * $h / 3 ) );
    my $data_image = Image::Imlib2->new_using_data( $w, $h, $rect );

    # If we have a non-opaque pixel, need to create a transparent image

    my $image = $alpha
        && $test->{blend}
        ? Image::Imlib2->new_using_data( $w, $h, $null x ( $w * $h ) )
        : Image::Imlib2->new( $w, $h );

    $image->set_color( @{ $pixels->[0] }[ 1 .. 3 ], $pixels->[0]->[0] )
        ;    # RGBA
    $image->fill_rectangle( 0, 0, $w, $h / 3 );
    $image->set_color( @{ $pixels->[1] }[ 1 .. 3 ], $pixels->[1]->[0] )
        ;    # RGBA
    $image->fill_rectangle( 0, $h / 3, $w, $h / 3 );
    $image->set_color( @{ $pixels->[2] }[ 1 .. 3 ], $pixels->[2]->[0] )
        ;    # RGBA
    $image->fill_rectangle( 0, 2 * $h / 3, $w, $h / 3 );

    for my $x ( 0 .. $w - 1 ) {
        for my $y ( 0 .. $h - 1 ) {
            my @p1 = $data_image->query_pixel( $x, $y );
            my @p2 = $image->query_pixel( $x,      $y );
            is_deeply( \@p1, \@p2, "$x,$y" );
        }
    }
}
