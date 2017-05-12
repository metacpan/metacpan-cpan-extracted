use strict;
use warnings;

use Test::More tests => 12;
use Image::WordCloud;

my $wc = Image::WordCloud->new();

# * 96 / 72
is($wc->_points_to_pixels(5), 5 * 96 / 72,	"_points_to_pixels() returns right value");

# * 72 / 96
is($wc->_pixels_to_points(5), 5 * 72 / 96,	"_points_to_pixels() returns right value");


$wc = Image::WordCloud->new(
	image_size      => [400, 300],
	border_padding  => 20
);

is($wc->width,  400, "width() returns right width");
is($wc->height, 300, "height() returns right height");

my ($l, $t, $r, $b) = $wc->_image_bounds();

is($l, 20,		"Left bound is right");
is($t, 20,		"Top bound is right");
is($r, $wc->width  - 20,		"Right bound is right");
is($b, $wc->height - 20,		"Bottom bound is right");


my $percent = 20;
$wc = Image::WordCloud->new(
	image_size      => [400, 300],
	border_padding  => $percent . '%'
);

($l, $t, $r, $b) = $wc->_image_bounds();

my $multiplier = $percent / 100;

is($l, $wc->width  * $multiplier,		"Left bound is right when done by percentage");
is($t, $wc->height * $multiplier,		"Top bound is right when done by percentage");

is($r, $wc->width -  $wc->width  * $multiplier,		"Right bound is righ when done by percentage");
is($b, $wc->height - $wc->height * $multiplier,		"Bottom bound is right when done by percentage");