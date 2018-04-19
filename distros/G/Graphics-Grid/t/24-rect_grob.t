#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Grob::Rect;

my @cases_constructor = (
    {
        params => [],
    },
    {
        params => [
            x      => 0.5,
            y      => 0.5,
            width  => 0.5,
            height => 0.5,
            gp     => { fill => "yellow" }
        ],
    },
);

for my $case (@cases_constructor) {
    my $grob = Graphics::Grid::Grob::Rect->new( @{ $case->{params} } );
    ok( $grob, 'constructor' );
}

done_testing;
