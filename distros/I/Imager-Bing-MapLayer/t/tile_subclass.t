#!/usr/bin/env perl

package Tile;

use Moose;
extends 'Imager::Bing::MapLayer::Tile';

use Path::Class;

override build_filename => sub {
    my ($self) = @_;
    my $file = file( $self->base_dir, $self->level,
        join( ',', @{ $self->tile_coords } ) . '.png' );
    $file->parent->mkpath;
    return $file->stringify;
};

package main;

use Test::Most;
use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use aliased
    'Imager::Bing::MapLayer::Utils' => 'Utils',
    qw/ latlon_to_pixel /;

use File::Temp qw/ tempdir /;
use Imager::Fill;
use Const::Fast;

const my $key => '1202020200032213';

my $cleanup = $ENV{TMP_NO_CLEANUP} ? 0 : 1;

my $tile;

lives_ok {
    $tile = Tile->new(
        quad_key  => $key,
        base_dir  => tempdir( CLEANUP => $cleanup ),
        overwrite => 1,
    );
}
"new";

isa_ok( $tile, 'Tile' );

note( $tile->base_dir );

is( $tile->level, length($key), "level" );

like( $tile->filename, qr{16/32787,21789\.png$}, "filename" );

is( $tile->width,  256, "width" );
is( $tile->height, 256, "height" );

is_deeply( $tile->pixel_origin, [ 8393472, 5577984, ], "pixel_origin" );

is( $tile->left, 8393472, "left" );
is( $tile->top,  5577984, "top" );

is( $tile->right,  8393472 + $tile->width - 1,  "right" );
is( $tile->bottom, 5577984 + $tile->height - 1, "bottom" );

is_deeply( $tile->tile_coords, [ 32787, 21789 ], "tile_coords" );

my @latlon = ( 51.5171, 0.1062 );    # London

ok( my @pixel = $tile->latlon_to_pixel(@latlon), "latlon_to_pixel" );

TODO: {

    # Because of a bug in Imager, we cannot distinguish between an
    # error and no pixels drawn.

    local $TODO = "bug in Imager::Draw->setpixel";

    dies_ok {
        $tile->setpixel(
            x     => $pixel[0],
            'y'   => $pixel[1],
            color => 'invalid-color'
        );
    }
    "setpixel error";

}

lives_ok {
    $tile->setpixel( x => $pixel[0], 'y' => $pixel[1], color => 'blue' );
}
"setpixel";

ok( my $color = $tile->getpixel( x => $pixel[0], 'y' => $pixel[1] ),
    "getpixel" );

note( explain $color);

is_deeply( [ $color->rgba ], [ 0, 0, 255, 255 ], "color" );

ok( my @colors = $tile->getpixel(
        x   => [ $pixel[0], $tile->left ],
        'y' => [ $pixel[1], $tile->top ]
    ),
    "getpixel (list context)"
);

note( explain \@colors );

is_deeply( [ map { [ $_->rgba ] } @colors ],
    [ [ 0, 0, 255, 255 ], [ 0, 0, 0, 0 ] ], "colors" );

lives_ok {
    $tile->setpixel( x => $tile->left, 'y' => $tile->top, color => 'green' );
}
"setpixel top-left";

lives_ok {
    $tile->setpixel(
        x     => $tile->right,
        'y'   => $tile->bottom,
        color => 'green'
    );
}
"setpixel bottom-right";

lives_ok {
    $tile->setpixel(
        x     => $tile->right + 1,
        'y'   => $tile->bottom + 1,
        color => 'red'
    );
}
"setpixel (out of bounds)";

lives_ok {
    $tile->setpixel(
        x     => $tile->left - 1,
        'y'   => $tile->top - 1,
        color => 'red'
    );
}
"setpixel (out of bounds)";

# 51.5171, 0.1062

my @poly = (
    [ 51.48224, -0.03124 ],
    [ 51.52071, 0.123 ],
    [ 51.5143,  0.17931 ],
    [ 51.47582, 0.2026 ],
);

my @pixels = @{ $tile->latlons_to_pixels( \@poly ) };
note( explain \@pixels );

lives_ok {
    $tile->polyline( points => \@pixels, color => 'black', aa => 1, );
}
"polyline";

# Test for line pixel - this will eventually be overwritten

ok( $color = $tile->getpixel(
        x   => $tile->left + 10,
        'y' => $tile->top + 216,
    ),
    "getpixel"
);

note( explain $color);

is_deeply( [ $color->rgba ], [ 0, 0, 0, 255 ], "color" );

lives_ok {
    $tile->line(
        x1    => $tile->left + 50,
        y1    => $tile->top - 50,
        x2    => $tile->left + 40,
        y2    => $tile->bottom + 50,
        color => 'darkgreen'
    );
}
"line";

lives_ok {

    my $fill = Imager::Fill->new( solid => 'yellow', combine => 'normal' );

    $tile->polygon(
        x    => [ $tile->left, $tile->left,      $tile->left + 100 ],
        'y'  => [ $tile->top,  $tile->top + 100, $tile->top + 100 ],
        fill => Imager::Fill->new(
            type    => "opacity",
            other   => $fill,
            opacity => 0.25,
        ),
    );

}
"polygon";

ok( $color = $tile->getpixel(
        x   => $tile->left + 5,
        'y' => $tile->top + 10,
    ),
    "getpixel"
);

note( explain $color);

is_deeply( [ $color->rgba ], [ 255, 255, 0, 64 ], "color" );

my $crop;

lives_ok {

    $crop = $tile->crop(
        left   => $tile->left,
        top    => $tile->top,
        width  => 100,
        height => 100,
    );

}
"crop";

ok( $crop, "cropped image" );
is( $crop->getwidth,  100, "crop width" );
is( $crop->getheight, 100, "crop height" );

lives_ok {

    $tile->compose(
        src  => $crop,
        left => $tile->left + 100,
        top  => $tile->top + 100,
    );

}
"compose";

ok( $color = $tile->getpixel(
        x   => $tile->left + 105,
        'y' => $tile->top + 110,
    ),
    "getpixel"
);

note( explain $color);

is_deeply( [ $color->rgba ], [ 255, 255, 0, 64 ], "color" );

# TODO - test that compose doesn't overwrite some of the content
# (e.g. black line)

lives_ok {

    $tile->paste(
        src  => $crop,
        left => $tile->left,
        top  => $tile->top + 100,
    );

}
"paste";

ok( $color = $tile->getpixel(
        x   => $tile->left + 5,
        'y' => $tile->top + 110,
    ),
    "getpixel"
);

note( explain $color);

is_deeply( [ $color->rgba ], [ 255, 255, 0, 64 ], "color" );

# Test that paste overwrites some of the content (e.g. black line)

ok( $color = $tile->getpixel(
        x   => $tile->left + 62,
        'y' => $tile->top + 195,
    ),
    "getpixel"
);

note( explain $color);

is_deeply( [ $color->rgba ], [ 255, 255, 0, 64 ], "color" );

lives_ok {

    my $fill = Imager::Fill->new( solid => 'blue', combine => 'normal' );

    $tile->box(
        box => [
            $tile->right - 50,
            $tile->top + 50,
            $tile->right,
            $tile->top + 80
        ],
        fill => Imager::Fill->new(
            type    => "opacity",
            other   => $fill,
            opacity => 0.55,
        ),
        filled => 0,
        color  => 'blue',
    );

}
"box";

ok( $color = $tile->getpixel(
        x   => $tile->left + 210,
        'y' => $tile->top + 60,
    ),
    "getpixel"
);

note( explain $color);

is_deeply( [ $color->rgba ], [ 0, 0, 255, 140 ], "color" );

lives_ok {

    my $fill = Imager::Fill->new( solid => 'orange', combine => 'normal' );

    $tile->circle(
        x      => $tile->left + 128,
        'y'    => $tile->top + 128,
        r      => 20,
        filled => 1,
        fill   => Imager::Fill->new(
            type    => "opacity",
            other   => $fill,
            opacity => 0.60,
        ),

    );

}
"circle";

note( $tile->filename );

done_testing;

