#!/usr/bin/env perl

# draws four 5-point-stars

use 5.014;
use warnings;

use Math::Trig qw(:pi);
use Graphics::Grid::Functions qw(:all);

sub star {
    my $a = 0.5 * sin( 72 * pi / 180 );
    my $b = 0.5 * cos( 72 * pi / 180 );

    my $triangle = polygon_grob(
        x => [ 0.5 - $a, 0.5, 0.5 + $a ],
        y => [ 0.5 + $b, 0.5, 0.5 + $b ],
        gp => gpar( fill => "yellow", col => "yellow" ),
    );

    for my $i ( 0 .. 4 ) {
        push_viewport( viewport( angle => 72 * $i ) );
        grid_draw($triangle);
        up_viewport();
    }
}

grid_rect( gp => gpar( fill => "blue" ) );    # background

my @vp_params = (
    {
        x      => .2,
        y      => .2,
        width  => .25,
        height => .25,
        angle  => 40
    },
    {
        x      => .8,
        y      => .8,
        width  => .3,
        height => .3,
        angle  => 90
    },
    {
        x      => .7,
        y      => .3,
        width  => .2,
        height => .2,
        angle  => 130
    },
    {
        x      => .3,
        y      => .7,
        width  => .15,
        height => .15,
        angle  => 210
    },
);

for my $params (@vp_params) {
    push_viewport( viewport(%$params) );
    star();
    up_viewport();
}

grid_write("stars.png");

