#!/usr/bin/perl

use strict;
use warnings;

use Graph::Geometric;
use Set::Scalar;
use Test::More;

my @cases = (
    [ [ 'A', 'B' ], 'ABCDE' ],
    [ [ 'A', 'C' ], 'ABC,ACDE' ],
    [ [ 'A', 'D' ], 'ABCD,ADE' ],
    [ [ 'B', 'E' ], 'ABE,BCDE' ],
    [ [ 'D', 'A' ], 'ABCD,ADE' ],
);

plan tests => scalar @cases;

my $face = Set::Scalar->new( 'A'..'E' );

for my $case (@cases) {
    my( $cut, $faces ) = @$case;

    my $prism5 = pentagonal prism;
    $prism5->carve_face( @$cut );

    my @faces = grep { $_->is_subset( $face ) } @{$prism5->get_graph_attribute( 'faces' )};
    is join( ',', sort map { join '', sort $_->members } @faces ), $faces;
}
