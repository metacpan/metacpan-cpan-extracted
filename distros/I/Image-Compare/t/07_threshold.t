# Tests for the "threshold" comparison method

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
	method => &Image::Compare::THRESHOLD,
	args   => 10,
);
# Max diff is 5, 5 * sqrt(3) == 8.66, which is less than 10, so this should
# return true indicating images are the same.
ok(compare(%args), 'THRESHOLD true result');

# Test two images that are more different
$args{image2} = make_image(
	[20, 10],
	[10, 20],
);
# Max diff is 10, 10 * sqrt(3) == 17.32, which is more than 10, so this should
# return false indicating images are different.
ok(!compare(%args), 'THRESHOLD false result');
