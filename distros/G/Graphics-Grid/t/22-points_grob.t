#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Grob::Points;

my @cases_constructor = (
    {
        params => {},
        elems  => 10,
    },
    {
        params => {
            x => [ map { rand() } (0 .. 9) ],
            y => [ map { rand() } (0 .. 9) ],
            pch => "A",
        },
        elems => 10,
    },
);

for my $case (@cases_constructor) {
    my $grob = Graphics::Grid::Grob::Points->new( %{ $case->{params} } );
    ok( $grob, 'constructor' );
    is( $grob->elems, $case->{elems}, '$grob->elems is ' . $case->{elems} );
}

done_testing;
