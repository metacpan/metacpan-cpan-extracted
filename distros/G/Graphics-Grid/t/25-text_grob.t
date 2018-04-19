#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Grob::Text;

my @cases_constructor = (
    {
        params => {
            label => 'SOMETHING NICE AND BIG',
            x     => 0.1,
            y     => 0.2,
            gp    => { fontsize => 20, col => "grey" },
        },
    },
);

for my $case (@cases_constructor) {
    my $grob = Graphics::Grid::Grob::Text->new( %{ $case->{params} } );
    ok( $grob, 'constructor' );
}

done_testing;
