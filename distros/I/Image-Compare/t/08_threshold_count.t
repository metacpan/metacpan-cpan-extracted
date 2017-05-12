# Tests for the "threshold_count" comparison method

use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok('Image::Compare', 'compare'); }
require "t/helper.pm";

# Test two images that are different, but not that different
my %args = (
	image1 => make_image(
		[10, 20],
		[20, 10],
	),
	image2 => make_image(
		[15, 15],
		[15, 15],
	),
	method => &Image::Compare::THRESHOLD_COUNT,
	args   => 10,
);
# Max diff is 5, 5 * sqrt(3) == 8.66, which is less than 10, so this should
# return 0, indicating that no pixels differ enough.
ok((compare(%args) == 0), "THRESHOLD_COUNT 0 pixels");

# Test two images that are more different
$args{image2} = make_image(
	[20, 10],
	[10, 20],
);
# Max diff is 10, 10 * sqrt(3) == 17.32, which is more than 10, so this should
# return 4, indicating that all four pixels differ too much.
ok((compare(%args) == 4), 'THRESHOLD_COUNT 4 pixels');
