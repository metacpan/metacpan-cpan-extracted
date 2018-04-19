## Please see file perltidy.ERR
#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Functions qw(:all);
use Graphics::Grid::GTree;

my @cases_constructor = (
    {
        params => [],
    },
    {
        params => [
            children => [
                circle_grob( x => .5, y => .8, r => .1 ),
                lines_grob( x => [ .5, .5 ],  y => [ .7, .2 ] ),    # body
                lines_grob( x => [ .5, .7 ],  y => [ .6, .7 ] ),    # right arm
                lines_grob( x => [ .5, .3 ],  y => [ .6, .7 ] ),    # left arm
                lines_grob( x => [ .5, .65 ], y => [ .2, 0 ] ),     # right leg
                lines_grob( x => [ .5, .35 ], y => [ .2, 0 ] ),     # left leg

            ],
            gp => gpar( col => "blue", fill => "yellow", lwd => '3' ),
        ]
    }
);

for my $case (@cases_constructor) {
    my $grob = Graphics::Grid::GTree->new( @{ $case->{params} } );
    ok( $grob, 'constructor' );
}

done_testing;
