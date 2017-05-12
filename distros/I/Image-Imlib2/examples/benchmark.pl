#!/usr/local/bin/perl

use lib qw(../lib ../blib/lib ../blib/arch);
use Benchmark;
use Image::Imlib2;

my $image = Image::Imlib2->new(100, 100);
$image->set_colour(255, 0, 0, 255);

timethese(-5, {
		'point' => \&point,
		'line' => \&line,
		'rect' => \&rectangle,
		'rect_f' => \&rectangle_fill,
		'ellipse' => \&ellipse,
		'ellipse_f' => \&ellipse_f,
	       });

#$image->save("benchmark.png");

sub point {
  $image->draw_point(rand(100), rand(100));
}

sub line {
  $image->draw_line(rand(100), rand(100), rand(100), rand(100));
}

sub rectangle {
  $image->draw_rectangle(rand(50), rand(50), rand(50), rand(50));
}

sub rectangle_fill {
  $image->fill_rectangle(rand(50), rand(50), rand(50), rand(50));
}

sub ellipse {
  $image->draw_ellipse(rand(50) + 25, rand(50) + 25, rand(24) + 1, rand(24) + 1);
}

sub ellipse_f {
  $image->fill_ellipse(rand(50) + 25, rand(50) + 25, rand(24) + 1, rand(24) + 1);
}
