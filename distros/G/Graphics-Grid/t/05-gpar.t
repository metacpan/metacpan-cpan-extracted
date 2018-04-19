#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::GPar;

use Graphics::Color::RGB;

my @cases_constructor = (
    {
        params => {
            col  => Graphics::Color::RGB->from_color_library("red"),
            fill => Graphics::Color::RGB->from_color_library("yellow")
        },
    },
    {
        params => {
            col => "red",
        },
    },
    {
        params => {
            col => [ "red", "blue" ],
        },
    },
    {
        params => {
            col => [
                Graphics::Color::RGB->from_color_library("red"),
                Graphics::Color::RGB->from_color_library("blue")
            ],
        },
    },
    {
        params => {
            col => [ "#ff0000", "#0000ff" ],
        },
    },
    {
        params => { col => "red", fill => "yellow" },
    },
);

for my $case (@cases_constructor) {
    my $gpar = Graphics::Grid::GPar->new( %{ $case->{params} } );
    ok( $gpar, 'constructor' );
}

{
    my $gp1 = Graphics::Grid::GPar->new(
        col => "red",
        lex => [ 1, 2, 3 ],
        cex => [ 1, 2 ]
    );
    my $gp2 = Graphics::Grid::GPar->new(
        col  => "green",
        fill => "blue",
        lex  => [2],
        cex  => [ 1, 0.5, 2 ]
    );

    my $gp_merged = $gp1->merge($gp2);
    ok( $gp_merged->col->[0]->equal_to( $gp1->col->[0] ),
        "non-cumulative merged value is from first gp if first gp has it" );
    ok(
        $gp_merged->fill->[0]->equal_to( $gp2->fill->[0] ),
        "non-cumulative merged value is from second gp if first gp has not it"
    );
    is( $gp_merged->lex, [ 2, 2, 3 ], "cumulative merged value" );
    is( $gp_merged->cex, [ 1, 1, 2 ], "cumulative merged value" );
    ok( !$gp_merged->has_lineheight,
        "empty parameter would still be empty in merged gp" );
}

done_testing;
