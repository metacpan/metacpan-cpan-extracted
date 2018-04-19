#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Grob::Circle;

my @cases_constructor = (
    {
        params => [],
    },
    {
        params => [
            x => 0.5,
            y => 0.5,
            r => [ 0.5, 0.3, 0.1 ],
            gp => { fill => "yellow" }
        ],
    },
);

for my $case (@cases_constructor) {
    my $grob = Graphics::Grid::Grob::Circle->new( @{ $case->{params} } );
    ok( $grob, 'constructor' );
}

done_testing;
