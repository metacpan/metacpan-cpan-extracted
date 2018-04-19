#!/usr/bin/env perl

use 5.014;
use warnings;

use Graphics::Grid::Functions qw(:all);

grid_rect();

grid_polyline(
    x => [
        ( map { $_ / 10 } ( 0 .. 4 ) ),
        (0.5) x 5,
        ( map { $_ / 10 } reverse( 6 .. 10 ) ),
        (0.5) x 5
    ],
    y => [
        (0.5) x 5,
        ( map { $_ / 10 } reverse( 6 .. 10 ) ),
        (0.5) x 5,
        ( map { $_ / 10 } ( 0 .. 4 ) ),
    ],
    id => [ ( 1 .. 5 ) x 4 ],
    gp => Graphics::Grid::GPar->new(
        col => [qw(black red green3 blue cyan)],
        lwd => 3,
    )
);

grid_write("polyline.png");

