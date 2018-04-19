#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Grob::Null;

my @cases_constructor = (
    {
        params => [],
    },
    {
        params => [ x => 0.5, y => 0.5 ],
    },
);

for my $case (@cases_constructor) {
    my $grob = Graphics::Grid::Grob::Null->new( @{ $case->{params} } );
    ok( $grob, 'constructor' );
}

done_testing;
