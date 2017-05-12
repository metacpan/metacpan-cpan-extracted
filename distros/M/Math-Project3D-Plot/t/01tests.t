# Tests for Math::Project3D::Plot
# (c) 2002-2003 Steffen Mueller, all rights reserved

use strict;
use warnings;

# use lib 'lib';
use Test::More tests => 12;

use Math::Project3D::Plot;

ok(1, 'Module compiled.'); # If we made it this far, we are ok.

my $img_size_x = 500;
my $img_size_y = 500;

my $img  = Imager->new(xsize => $img_size_x, ysize => $img_size_y);
my $proj = Math::Project3D->new(
   plane_basis_vector => [ 0, 0, 0 ],
   plane_direction1   => [ .4, 1, 0 ],
   plane_direction2   => [ .4, 0, 1 ],
);

$proj->new_function(
  't,u', '$t', '$u', '$t + $u',
);

my $color      = Imager::Color->new(0,   0, 0);
my $x_axis     = Imager::Color->new(255, 0, 0);
my $y_axis     = Imager::Color->new(0, 255, 0);
my $z_axis     = Imager::Color->new(0,   0, 255);
my $background = Imager::Color->new(255,255,255);

$img->box(
  color  => $background,
  xmin   => 0,
  ymin   => 0,
  xmax   => $img_size_x,
  ymax   => $img_size_y,
  filled => 1,
);

ok(ref $img eq 'Imager', "Created Imager image and Math::Project3D object.");

my $plotter = Math::Project3D::Plot->new(
  image      => $img,
  projection => $proj,
  scale      => 2,
);

ok(ref $plotter eq 'Math::Project3D::Plot', "Created plotter object.");

foreach (0..10) {
   $plotter->plot(color => $color, params=> [$_,$_]);
   $plotter->plot(color => $color, params=> [0,$_]);
   $plotter->plot(color => $color, params=> [$_,0]);
}

ok(1, "plot did not croak.");

my @params;
foreach (1..10) {
   push @params, [$_, $_*2];
}

$plotter->plot_list(
  color  => $color,
  params => \@params,
  type   => 'line',
);

ok(1, "plot_list as a line did not croak.");

$plotter->plot_list(
  color  => $color,
  params => \@params,
  type   => 'points',
);

ok(1, "plot_list as points did not croak.");

$plotter->plot_range(
  color  => $color,
  params => [
              [-10, 0, 1],
              [-10, 0, 1],
            ],
  type   => 'line',
);

ok(1, "plot_range as a line did not croak.");

$plotter->plot_range(
  color  => $color,
  params => [
              [-10, 0, 1],
              [-10, 0, 1],
            ],
  type   => 'points',
);

ok(1, "plot_range as points did not croak.");


$plotter->plot_range(
  color  => $color,
  params => [
              [-10, 0, 1],
              [-10, 0, 1],
            ],
  type   => 'multiline',
);

ok(1, "plot_range as multiline did not croak.");

$plotter->plot_axis( # x axis
  vector => [1, 0, 0],
  color  => $x_axis,
  length => 200,
);

ok(1, "plot_axis (x axis) did not croak.");

$plotter->plot_axis( # y axis
  vector => [0, 1, 0],
  color  => $y_axis,
  length => 200,
);

ok(1, "plot_axis (y axis) did not croak.");

$plotter->plot_axis( # z axis
  vector => [0, 0, 1],
  color  => $z_axis,
  length => 200,
);

ok(1, "plot_axis (z axis) did not croak.");


# $img->write(file=>'t.png') or
#         die $img->errstr;

# ok(0, "Forgot to remove the line that writes the image to disk");

