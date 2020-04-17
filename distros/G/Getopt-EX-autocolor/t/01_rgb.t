use strict;
use Test::More 0.98;

use Getopt::EX::autocolor qw(rgb_to_brightness);

is(rgb_to_brightness(65535, 65535, 65535), 100, "white");
is(rgb_to_brightness(65535,     0,     0),  30, "red");
is(rgb_to_brightness(    0, 65535,     0),  59, "green");
is(rgb_to_brightness(    0,     0, 65535),  11, "blue");
is(rgb_to_brightness(    0,     0,     0),   0, "black");

is(rgb_to_brightness({ max=>255 }, 255, 255, 255), 100, "max=255 white");
is(rgb_to_brightness({ max=>255 }, 255,   0,   0),  30, "max=255 red");
is(rgb_to_brightness({ max=>255 },   0, 255,   0),  59, "max=255 green");
is(rgb_to_brightness({ max=>255 },   0,   0, 255),  11, "max=255 blue");
is(rgb_to_brightness({ max=>255 },   0,   0,   0),   0, "max=255 black");

done_testing;
