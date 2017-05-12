use strict;
use warnings;

use Test::More tests => 5;
use Image::WordCloud;

my $wc = Image::WordCloud->new();

# Detect a collision
is(
	$wc->_detect_collision(
		0, 0, 5, 5, # Box at 0,0 that is 5px wide and high
		2, 2, 3, 3, # Box at 2x2 that is 5px wide and high
	),
	1
);


# Detect a collision with one box inside the other
is(
	$wc->_detect_collision(
		5, 5, 10, 10, # Box at 5,5 that is 10px wide and high
		8, 8, 3, 3, # Box at 8,8 that is 3x wide and high
	),
	1
);

# Detect a non-collision
is(
	$wc->_detect_collision(
		0,   0, 5, 5,   # Box at 0,0 that is 5px wide and high
		20, 20, 5, 5, # Box at 20x20 that is 5px wide and high
	),
	0
);

# Boxes right next to each other don't collide
is(
	$wc->_detect_collision(
		0, 0, 5, 5,   # Box at 0,0 that is 5px wide and high
		0, 6, 5, 5, # Box at 20x20 that is 5px wide and high
	),
	0
);

# Dimensionless boxes collide
is(
	$wc->_detect_collision(
		0, 0, 0, 0, # Box at 0,0 that is 5px wide and high
		0, 0, 0, 0, # Box at 20x20 that is 5px wide and high
	),
	1
);