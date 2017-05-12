use strict;
use warnings;

use Test::More;

use Image::Magick::Chart;

# ------------------------

my($charter) = Image::Magick::Chart -> new
(
	x_axis_data				=> [0, 20, 40, 60, 80, 100],
	x_axis_labels			=> [0, 20, 40, 60, 80, 100],
	x_data					=> [15, 5, 70, 25, 45, 20, 65],
	y_axis_data				=> [1 .. 7, 8], # 7 data points, plus 1 to make result pretty.
	y_axis_labels			=> [(map{"($_)"} reverse (1 .. 7) ), ''],
);

ok(defined $charter);
ok($charter -> isa('Image::Magick::Chart') );
ok($charter -> image -> isa('Image::Magick') );
ok($charter -> bg_color eq 'white');
ok($charter -> y_pixels_per_unit == 20);

done_testing();
