use strict;
use Test::More 0.98;

use Getopt::EX::termcolor qw(rgb_to_luminance);

is(rgb_to_luminance(255, 255, 255), 100, "white");
is(rgb_to_luminance(255,   0,   0),  30, "red");
is(rgb_to_luminance(  0, 255,   0),  59, "green");
is(rgb_to_luminance(  0,   0, 255),  11, "blue");
is(rgb_to_luminance(  0,   0,   0),   0, "black");

is(rgb_to_luminance({ max=>4096 }, 4096, 4096, 4096), 100, "max=4096 white");
is(rgb_to_luminance({ max=>4096 }, 4096,    0,    0),  30, "max=4096 red");
is(rgb_to_luminance({ max=>4096 },    0, 4096,    0),  59, "max=4096 green");
is(rgb_to_luminance({ max=>4096 },    0,    0, 4096),  11, "max=4096 blue");
is(rgb_to_luminance({ max=>4096 },    0,    0,    0),   0, "max=4096 black");

is(rgb_to_luminance({ max=>65535 }, 65535, 65535, 65535), 100, "max=65535 white");
is(rgb_to_luminance({ max=>65535 }, 65535,     0,     0),  30, "max=65535 red");
is(rgb_to_luminance({ max=>65535 },     0, 65535,     0),  59, "max=65535 green");
is(rgb_to_luminance({ max=>65535 },     0,     0, 65535),  11, "max=65535 blue");
is(rgb_to_luminance({ max=>65535 },     0,     0,     0),   0, "max=65535 black");

done_testing;
