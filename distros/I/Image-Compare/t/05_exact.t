# Tests for the "exact" comparison method

use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok('Image::Compare'); }
require "t/helper.pm";

# Test two images that are the same
my %args = (
	image1 => make_image(
		[10, 20],
		[20, 10],
	),
	image2 => make_image(
		[10, 20],
		[20, 10],
	),
	method => &Image::Compare::EXACT,
);
ok(Image::Compare->new(%args)->compare(), 'EXACT true result');

# Test two images that are NOT the same
$args{image2} = make_image(
	[20, 10],
	[10, 20],
);
ok(!Image::Compare->new(%args)->compare(), 'EXACT false result');

