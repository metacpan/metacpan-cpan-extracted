# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GD-Window.t'

#########################

use Test::More tests => 5;
BEGIN { 
  use_ok('GD'); 
  use_ok('GD::Window');
};

#########################

my $im1 = GD::Image->new(100, 100);
my $im2 = GD::Image->new(100, 100);
ok(defined $im1);
ok(defined $im2);

my $win = GD::Window->new($im1, -1000, -1000, 1000, 1000, 25, 25, 75, 75);
ok(defined $win);

my $col = $im1->colorClosest(50, 60, 70);

# The test strategy is to draw a bunch of shapes in the window and
# then manually do the translation to draw the shapes in another
# image.  Then do a comparison between the two images.

# ok($win->setPixel(900, -400, $col));

# Try all the supported methods
#   setPixel            => {x => [0],       y => [1]},
#   line                => {x => [0,2],     y => [1,3]},
#   dashedLine          => {x => [0,2],     y => [1,3]},
#   rectangle           => {x => [0,2],     y => [1,3]},
#   filledReactangle    => {x => [0,2],     y => [1,3]},
#   ellipse             => {x => [0],       y => [1],         w => [2],          h => [3]},
#   filledEllipse       => {x => [0],       y => [1],         w => [2],          h => [3]},
#   arc                 => {x => [0],       y => [1],         w => [2],          h => [3]},
#   filledArc           => {x => [0],       y => [1],         w => [2],          h => [3]},
#   fill                => {x => [0],       y => [1]},
#   fillToBorder        => {x => [0],       y => [1]},
#   copy                => {x => [1],       y => [2]},
#   copyMerge           => {x => [1],       y => [2]},
#   copyMergeGray       => {x => [1],       y => [2]},
#   copyResized         => {x => [1],       y => [2],         w => [5],          h => [6]},
#   copyResampled       => {x => [1],       y => [2],         w => [5],          h => [6]},
#   copyRotated         => {x => [1],       y => [2]},
#   string              => {x => [1],       y => [2]},
#   stringUp            => {x => [1],       y => [2]},
#   char                => {x => [1],       y => [2]},
#   charUp              => {x => [1],       y => [2]},
#   stringFT            => {x => [4],       y => [5]},
#   stringFTCircle      => {x => [0],       y => [1]},
#   clip                => {x => [0,2],     y => [1,3]},


