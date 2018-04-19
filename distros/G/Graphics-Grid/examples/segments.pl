#!perl

use 5.014;
use warnings;

use Graphics::Grid::Functions qw(:all);

grid_rect();

grid_segments(
    x0 => [ 0, 0 ],
    x1 => [ 1, 1 ],
    y0 => [ 0, 1 ],
    y1 => [ 1, 0 ],
    gp => Graphics::Grid::GPar->new(
        col => [qw(black red)],
        lwd => 3
    ),
);

grid_write("segments.png");

