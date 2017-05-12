# Tests for using match masks

use Test::More tests => 18;

BEGIN { use_ok('Image::Compare', 'compare'); }
require "t/helper.pm";

# Use avg_threshold with a mask to cover one of the pixels.
my %args = (
	image1 => make_image(
		[10, 20],
		[20, 10],
	),
	image2 => make_image(
		[11, 21],
		[15, 12],
	),
	mask => make_image(
		channels => 1,
		pixels => [
			[254, 123],
			[0  , 255],
		],
	),
	method => &Image::Compare::AVG_THRESHOLD,
	args   => {
		type  => &Image::Compare::AVG_THRESHOLD::MEAN,
		value => 4.1,
	},
);
# Total diff is 1 + 1 + 5 = 7.  7 * sqrt(3) = 12.1, divide by 3 is 4.0.
# If we set our threshold to 4.1, we should get a true result.
ok(compare(%args), 'MEAN true result with mask');

# If we set the threshold to 3.9, then we should get a false result.
$args{args}{value} = 3.9;
ok(!compare(%args), 'MEAN false result with mask');

# Now we make sure masks work properly when used with the IMAGE comparator.
$args{method} = &Image::Compare::IMAGE;
$args{args} = undef;
$args{image1} = make_image(
	[10, 10],
	[10, 10],
);
$args{image2} = make_image(
	[240, 3],
	[10, 92],
);
my $ret = compare(%args);

isa_ok($ret, 'Imager', 'Masked image result object');
# That last pixel should be white because we ignored it in the comparison.
verify_image('Greyscale', $ret, [[230, 7], [0, 0]]);

# Now we test masks with the THRESHOLD comparator
$args{image2} = make_image(
	[15, 15],
	[15, 22],
);
$args{method} = &Image::Compare::THRESHOLD;
$args{args} = 10;
# The max diff is 12, 12 * sqrt(3) == 20.8.  However, the mask should tell
# processing to ignore that pixel, so the max diff is 5, 5 * sqrt(3) == 8.66,
# which is less than 10, so this should return true indicating images are
# the same.
ok(compare(%args), 'Masked THRESHOLD true result');

# Test two images that are different, but not that different
$args{method} = &Image::Compare::THRESHOLD_COUNT;
# As before, this should return 0 because the only pixel pair which exceeds the
# threshold is masked.
ok((compare(%args) == 0), "Masked THRESHOLD_COUNT 0 pixels");
