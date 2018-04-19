#!/usr/bin/env perl

use 5.014;
use warnings;

use Graphics::Grid::Functions qw(:all);

grid_rect();

grid_text(
    label => [ ('SOMETHING NICE AND BIG') x 4 ],
    x     => 0.5,
    y     => 0.5,
    rot   => [ map { $_ * 45 } ( 0 .. 3 ) ],
    gp    => { fontsize => 20, col => "grey" }
);

grid_write("text.png");

