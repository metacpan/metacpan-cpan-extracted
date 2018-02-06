#!/usr/bin/env perl
use Inline C;
use Graphics::Raylib '+family';

use strict;
use warnings;

my $SIZE  = 500;
my $ITERS = 250;
my $STEP = $ENV{RAYLIB_FRACTAL_STEP} // 50;
my ($cX, $cY) = (-0.7, 0.27015);
my ($moveX, $moveY) = (0, 0);
my $zoom = 1;

my $g = Graphics::Raylib->window($SIZE*2, $SIZE*1);

my @julia      = map [(0)x$SIZE], 0..$SIZE-1;
my @mandelbrot = map [(0)x$SIZE], 0..$SIZE-1;
# coloring in the callback is reaaaaally slow, so we don't do it TODO find out why
my @args = (color => sub { shift }, width => $SIZE * 1, height => $SIZE * 1);
my $julia      = Graphics::Raylib::Shape->bitmap(matrix => \@julia,      x => -$SIZE*1, @args);
my $mandelbrot = Graphics::Raylib::Shape->bitmap(matrix => \@mandelbrot, x =>  $SIZE*1, @args);
$g->fps(50);

for (my $y = 0; $y <= $SIZE; $y += $STEP) {
    $g->clear;
    $julia->matrix = \@julia;
    $mandelbrot->matrix = \@mandelbrot;

    Graphics::Raylib::draw {
        $julia->draw;
        $mandelbrot->draw;
    };

    for (my $i = $y; $i < $y + $STEP; $i++) {
        for (my $x = 0; $x < $SIZE; $x++) {
            $julia[$i][$x]      = julia($x, $i);
            $mandelbrot[$i][$x] = mandelbrot($x, $i);
        }
    }
}
sleep($ENV{RAYLIB_TEST_SLEEP_SECS} // 2);

sub julia {
    my ($x, $y) = @_;
    my $i = julia_i($x, $y, $SIZE, $ITERS, $zoom, $moveX, $moveY, $cX, $cY);
    return Graphics::Raylib::Color::hsv(abs($i / $ITERS * 360), 1, $i > 0 ? 1 : 0);
}
sub mandelbrot {
    my ($x, $y) = @_;
    my $i = mandelbrot_i($x, $y, $SIZE, $ITERS);
    return Graphics::Raylib::Color::hsv(abs($i / $ITERS * 360), 1, $i > 0 ? 1 : 0);
}

__END__
__C__

#include <complex.h>

int julia_i(int x, int y, int SIZE, int ITERS, double zoom, double moveX, double moveY, double cX, double cY)
{
    complex double z =   (1.5 * (x - SIZE / 2) / (0.5 * zoom * SIZE) + moveX)
                     + I*((y - SIZE / 2) / (0.5 * zoom * SIZE) + moveY);

    int i = ITERS;
    while (cabs(z) < 2.0 && --i >= 0) {
        z = z*z + cX + I*cY;
    }
    return i;
}
int mandelbrot_i(int x, int y, int SIZE, int ITERS)
{

    complex double c = -2 + (2.5*x)/SIZE +I*(-1.25 + (2.5*y)/SIZE);
    complex double z = c;

    int i = ITERS;
    while (cabs(z) < 4.0 && --i >= 0) {
        z = z*z + c;
    }

    return i;
}

