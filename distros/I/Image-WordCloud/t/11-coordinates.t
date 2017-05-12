use strict;
use warnings;

use Test::More tests => 11;
use Test::Fatal;
use Image::WordCloud;
use GD;
use Math::PlanePath::TheodorusSpiral;

my ($height, $width) = (40, 40);
my $wc = Image::WordCloud->new(
	image_size => [$height, $width]
);

my $gd = GD::Image->new($height, $width);

my $path = Math::PlanePath::TheodorusSpiral->new;

my ($bound_x, $bound_y) = (10, 10);

my ($this_x, $this_y) = $wc->_new_coordinates($gd, $path, 1, $bound_x, $bound_y);

ok($this_x > 0 && $this_x < $gd->width,  "New X coord with image bounds");
ok($this_y > 0 && $this_y < $gd->height, "New Y coord with image bounds");

SKIP: {
	skip "No longer validating params in _new_coordinates(), it takes too long when the method is being called thousands of times", 9;
		
	isnt(
		exception { $wc->_new_coordinates('foo', $path, 1, $bound_x, $bound_y) },
		undef,
		"_new_coordinates() requires GD::Image as first arg"
	);
	
	isnt(
		exception { $wc->_new_coordinates($gd, 'foo', 1, $bound_x, $bound_y) },
		undef,
		"_new_coordinates() requires Math::PlanePath::TheodorusSpiral as second arg"
	);
	
	isnt(
		exception { $wc->_new_coordinates($gd, $path, 'foo', $bound_x, $bound_y) },
		undef,
		"_new_coordinates() requires integer as third arg"
	);
	
	isnt(
		exception { $wc->_new_coordinates($gd, $path, 1, 'foo', $bound_y) },
		undef,
		"_new_coordinates() requires int/float as fourth arg
	");
	
	isnt(
		exception { $wc->_new_coordinates($gd, $path, 1, $bound_x, 'foo') },
		undef,
		"_new_coordinates() requires int/float as fifth arg"
	);
	
	ok($wc->_new_coordinates($gd, $path, 1, 10.25, $bound_y), "_new_coordinates() accepts float as fourth arg");
	ok($wc->_new_coordinates($gd, $path, 1, $bound_x, 10.25), "_new_coordinates() accepts float as fifth arg");
	
	ok($wc->_new_coordinates($gd, $path, 0, $bound_x, $bound_y),  "_new_coordinates() takes zero for iteration");
	ok($wc->_new_coordinates($gd, $path, -5, $bound_x, $bound_y), "_new_coordinates() takes negative iteration");
}
