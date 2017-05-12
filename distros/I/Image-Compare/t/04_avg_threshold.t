# Tests for the "avg_threshold" comparison method

use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok('Image::Compare', 'compare'); }
require "t/helper.pm";

# Test "mean" average type with true result
my %args = (
	image1 => make_image(
		[10, 20],
		[20, 10],
	),
	image2 => make_image(
		[11, 21],
		[15, 12],
	),
	method => &Image::Compare::AVG_THRESHOLD,
	args   => {
		type  => &Image::Compare::AVG_THRESHOLD::MEAN,
		value => 4,
	},
);
# Total diff is 1 + 1 + 5 + 2 = 9.  9 * sqrt(3) = 15.6, divide by 4 is 3.9.
# If we set our threshold to 4, we should get a true result.
ok(compare(%args), 'MEAN true result');

# Test "mean" average type with true result
# If we set the threshold to 3.7, then we should get a false result.
$args{args}{value} = 3.7;
ok(!compare(%args), 'MEAN false result');

# Test "median" average with true result
$args{args}{type} = &Image::Compare::AVG_THRESHOLD::MEDIAN;
# Diffs are 1, 1, 5 and 2.  Middle two values are 1 and 2, so the median 
# will be 1.5.  1.5 * sqrt(3) is 2.6, so if we set the value to 3, we should
# get a true value.
$args{args}{value} = 3;
ok(compare(%args), 'MEDIAN true result');

# And if we set it to 2.3, we should get false
$args{args}{value} = 2.3;
ok(!compare(%args), 'MEDIAN false result');
