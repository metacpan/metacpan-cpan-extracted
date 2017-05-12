#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Image::PNM;

my $image = Image::PNM->new('t/data/P6.ppm');

is($image->width, 6);
is($image->height, 8);
is($image->max_pixel_value, 255);
is_deeply($image->raw_pixel(1, 2), [0, 84, 255]);
is_deeply($image->pixel(4, 1), [1, 0, 0]);

is($image->as_string('P1'), <<IMAGE);
P1
6 8
0 0 0 0 0 0
0 0 1 1 0 0
0 1 0 0 1 0
1 0 0 0 0 1
1 1 1 1 1 1
1 0 0 0 0 1
1 0 0 0 0 1
0 0 0 0 0 0
IMAGE

is($image->as_string('P2'), <<IMAGE);
P2
6 8
255
255 255 255 255 255 255
255 255 78 78 255 255
255 0 255 255 0 255
0 255 255 255 255 0
0 54 54 54 54 0
0 255 255 255 255 0
0 255 255 255 255 0
255 255 255 255 255 255
IMAGE

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

is($image->as_string('P4') . "\n", <<IMAGE);
P4
6 8
\x00\x30\x48\x84\xfc\x84\x84\x00
IMAGE

is($image->as_string('P5') . "\n", <<IMAGE);
P5
6 8
255
\xff\xff\xff\xff\xff\xff\xff\xff\x4e\x4e\xff\xff\xff\x00\xff\xff\x00\xff\x00\xff\xff\xff\xff\x00\x00\x36\x36\x36\x36\x00\x00\xff\xff\xff\xff\x00\x00\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff
IMAGE

is($image->as_string('P6') . "\n", <<IMAGE);
P6
6 8
255
\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x54\xff\x00\x54\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\xff\xff\xff\xff\xff\xff\x00\x00\x00\xff\xff\xff\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\xff\x00\x00\xff\x00\x00\xff\x00\x00\xff\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff
IMAGE

done_testing;
