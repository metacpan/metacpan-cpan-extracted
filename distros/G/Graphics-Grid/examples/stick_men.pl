#!/usr/bin/env perl

# draws three stick men in a tunnel

use 5.014;
use warnings;

use Graphics::Grid::Functions qw(:all);

my $stickman_grob = gtree(
    children => [
        circle_grob( x => .5, y => .8, r => .1 ),
        lines_grob( x => [ .5, .5 ],  y => [ .7, .2 ] ),    # body
        lines_grob( x => [ .5, .7 ],  y => [ .6, .7 ] ),    # right arm
        lines_grob( x => [ .5, .3 ],  y => [ .6, .7 ] ),    # left arm
        lines_grob( x => [ .5, .65 ], y => [ .2, 0 ] ),     # right leg
        lines_grob( x => [ .5, .35 ], y => [ .2, 0 ] ),     # left leg

    ],
    gp => gpar( col => "blue", fill => "yellow", lwd => '3' ),
);

grid_rect();

for ( 1 .. 100 ) {
    my $vp = viewport( height => .9, width => .9 );
    push_viewport($vp);
    grid_rect();
}

up_viewport(0);    # get back to root viewport

grid_lines( x => [ .05, .95 ], y => [ .95, .05 ] );
grid_lines( x => [ .05, .95 ], y => [ .05, .95 ] );

for my $i ( 1 .. 20 ) {
    push_viewport( viewport( height => .9, width => .9 ) );

    # person 1:
    if ( $i == 5 ) {
        push_viewport( viewport( x => .8 ) );
        grid_draw($stickman_grob);
        up_viewport();
    }

    # person 2:
    if ( $i == 10 ) {
        push_viewport( viewport( x => .2, angle => 45 ) );
        grid_draw($stickman_grob);
        up_viewport();
    }

    # person 3:
    if ( $i == 20 ) {
        push_viewport( viewport( angle => -45 ) );
        grid_draw($stickman_grob);
    }
}

grid_write("stick_men.png");

