#!/usr/bin/env perl

use 5.014;
use warnings;

use Graphics::Grid::Functions qw(:all);

grid_rect();

grid_points(
    x => [ map { rand() } ( 0 .. 9 ) ],
    y => [ map { rand() } ( 0 .. 9 ) ],
    pch  => "A",
    size => unit( [ map { 0.5 + rand() } ( 0 .. 9 ) ], 'char' ),
    gp   => gpar(),
);

grid_write("points.png");
