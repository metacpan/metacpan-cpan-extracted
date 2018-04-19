#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Grob::Lines;
use Graphics::Grid::Grob::Polygon;
use Graphics::Grid::Grob::Polyline;
use Graphics::Grid::Grob::Segments;

my @cases_constructor_polyline = (
    {
        params     => {},
        elems      => 1,
        unique_ids => [0],
    },
    {
        params => {
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
                lwd => 3
            ),
        },
        elems      => 5,
        unique_ids => [ 1 .. 5 ],
    },
    {    # nothing for id
        params => {
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
            gp => Graphics::Grid::GPar->new(
                col => [qw(black red green3 blue cyan)],
                lwd => 3
            ),
        },
        elems      => 1,
        unique_ids => [0],
    },
);

for my $case (@cases_constructor_polyline) {
    my $grob = Graphics::Grid::Grob::Polyline->new( %{ $case->{params} } );
    ok( $grob, 'polyline constructor' );
    is( $grob->elems, $case->{elems}, '$grob->elems is ' . $case->{elems} );

    if ( exists $case->{unique_ids} ) {
        is( $grob->unique_ids, $case->{unique_ids}, 'unique_ids()' );
    }
}

{
    my $grob = Graphics::Grid::Grob::Polyline->new(
        %{ $cases_constructor_polyline[1]->{params} } );
    my %indexes_by_id =
      map { $_ => $grob->indexes_by_id($_) } ( @{ $grob->unique_ids } );
    is(
        \%indexes_by_id,
        {
            1 => [ 0, 5, 10, 15 ],
            2 => [ 1, 6, 11, 16 ],
            3 => [ 2, 7, 12, 17 ],
            4 => [ 3, 8, 13, 18 ],
            5 => [ 4, 9, 14, 19 ]
        },
        'indexes_by_id()'
    );
}

my @cases_constructor_lines = (
    {
        params => {},
        elems  => 1,
    },
    {
        params => {
            x  => [ 0,   0.5, 1,   0.5 ],
            y  => [ 0.5, 1,   0.5, 0 ],
            gp => Graphics::Grid::GPar->new(
                lwd => 3
            ),
        },
        elems => 1,
    },
);

for my $case (@cases_constructor_lines) {
    my $grob = Graphics::Grid::Grob::Lines->new( %{ $case->{params} } );
    ok( $grob, 'lines constructor' );
    is( $grob->elems, $case->{elems}, '$grob->elems is ' . $case->{elems} );
}

my @cases_constructor_polygon = (
    {
        params => {},
        elems  => 1,
    },
    {
        params => {
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
                fill => [qw(black red green3 blue cyan)],
            ),
        },
        elems => 5,
    },
);

for my $case (@cases_constructor_polygon) {
    my $grob = Graphics::Grid::Grob::Polygon->new( %{ $case->{params} } );
    ok( $grob, 'polygon constructor' );
    is( $grob->elems, $case->{elems}, '$grob->elems is ' . $case->{elems} );
}

my @cases_constructor_segments = (
    {
        params => {},
        elems  => 1,
    },
    {
        params => {
            x0 => [ 0, 1 ],
            x1 => [ 1, 0 ],
            y0 => [ 0, 1 ],
            y1 => [ 1, 0 ],
            gp => Graphics::Grid::GPar->new(
                col => [qw(black red)],
                lwd => 3
            ),
        },
        elems => 2,
    },
);

for my $case (@cases_constructor_segments) {
    my $grob = Graphics::Grid::Grob::Segments->new( %{ $case->{params} } );
    ok( $grob, 'segments constructor' );
    is( $grob->elems, $case->{elems}, '$grob->elems is ' . $case->{elems} );
}

done_testing;
