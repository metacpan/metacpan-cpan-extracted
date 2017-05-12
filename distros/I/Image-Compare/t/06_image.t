# Tests for the "image" comparison method

use warnings;
use strict;

use Test::More tests => 42;

BEGIN {
	use_ok('Image::Compare', 'compare');
	use_ok('Imager', ':handy');
	use_ok('Imager::Fountain');
}
require "t/helper.pm";

# This is real simple -- just make sure that the image we get back is
# the right shape and has the right color values for the pixels
# First, let's do grayscale.
my %args = (
	image1 => make_image(
		[10, 10],
		[10, 10],
	),
	image2 => make_image(
		[240, 3],
		[10, 92],
	),
	method => &Image::Compare::IMAGE,
);
my $ret = compare(%args);

isa_ok($ret, 'Imager', 'Greyscale result object');
# All the color values here are obtained by simple calculation.
verify_image('Greyscale', $ret, [[230, 7], [0, 82]]);

# Now we test the color output mode
$args{args} = 1;
$ret = compare(%args);

isa_ok($ret, 'Imager', 'Color result object');
# In color mode, differences are mapped to triplets of red / green / blue.
# If the difference is between 0 and 127, the color ramp is linear from red
# to green -- if it between 128 and 255, the ramp is from green to blue.  I
# will omit the detailed math here.
verify_image(
	'Color',
	$ret,
	[[
		[0, 50, 205],
		[241, 14, 0],
	],[
		[255, 0, 0],
		[91, 164, 0]
	],],
);

# And now we test the case where a user passes in their own fountain.  In this
# case, we'll just make a fountain that's the opposite of the default
# color gradient; instead of going from red to green to blue, we'll go from
# blue to green to red.  This should make the math pretty easy.
$args{args} = Imager::Fountain->simple(
  positions => [          0.0,           0.5,           1.0],
  colors    => [NC(0, 0, 255), NC(0, 255, 0), NC(255, 0, 0)],
);
$ret = compare(%args);
isa_ok($ret, 'Imager', 'User-supplied fountain result object');
verify_image(
	'User-supplied',
	$ret,
	[[
		[205, 50, 0],
		[0, 14, 241],
	],[
		[0, 0, 255],
		[0, 164, 91]
	],],
);
