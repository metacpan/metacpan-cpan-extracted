#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Grob::Zero;

my @cases_constructor = (
    {
        params => [],
    },
);

for my $case (@cases_constructor) {
    my $grob = Graphics::Grid::Grob::Zero->new( @{ $case->{params} } );
    ok( $grob, 'constructor' );
}

done_testing;
