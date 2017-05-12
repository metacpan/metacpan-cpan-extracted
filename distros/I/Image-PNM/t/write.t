#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Image::PNM;

{
    my $image = Image::PNM->new;
    $image->width(6);
    $image->height(8);
    $image->max_pixel_value(255);

    for my $col (0..5) {
        for my $row (0..7) {
            $image->pixel($row, $col, [1, 1, 1]);
        }
    }
    $image->raw_pixel(1, 2, [0, 84, 255]);
    $image->raw_pixel(1, 3, [0, 84, 255]);
    $image->raw_pixel(2, 1, [0, 0, 0]);
    $image->raw_pixel(2, 4, [0, 0, 0]);
    $image->raw_pixel(3, 0, [0, 0, 0]);
    $image->raw_pixel(3, 5, [0, 0, 0]);
    $image->raw_pixel(4, 0, [0, 0, 0]);
    $image->raw_pixel(4, 1, [255, 0, 0]);
    $image->raw_pixel(4, 2, [255, 0, 0]);
    $image->raw_pixel(4, 3, [255, 0, 0]);
    $image->raw_pixel(4, 4, [255, 0, 0]);
    $image->raw_pixel(4, 5, [0, 0, 0]);
    $image->raw_pixel(5, 0, [0, 0, 0]);
    $image->raw_pixel(5, 5, [0, 0, 0]);
    $image->raw_pixel(6, 0, [0, 0, 0]);
    $image->raw_pixel(6, 5, [0, 0, 0]);

    is($image->as_string('P3'), <<IMAGE);
P3
6 8
255
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
255 255 255 255 255 255 0 84 255 0 84 255 255 255 255 255 255 255
255 255 255 0 0 0 255 255 255 255 255 255 0 0 0 255 255 255
0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0
0 0 0 255 0 0 255 0 0 255 0 0 255 0 0 0 0 0
0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0
0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0
255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255
IMAGE
}

done_testing;
