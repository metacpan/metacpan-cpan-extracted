# utils.t

use Test::Most;

use Geo::JSON::Utils qw/ compute_bbox compare_positions /;

note "compute_bbox";

dies_ok { compute_bbox() } "dies ok with no args";

dies_ok { compute_bbox( [ 1, 2 ] ) } "dies ok with single position";

my @tests = (
    {   positions => [ [ 1, 2 ], [ 3, 4 ] ],
        bbox => [ 1, 2, 3, 4 ],
    },

    {   positions => [ [ 1, 4 ], [ 3, 2 ] ],
        bbox => [ 1, 2, 3, 4 ],
    },

    {   positions => [ [ -1, 4 ], [ 3, 2 ] ],
        bbox => [ -1, 2, 3, 4 ],
    },

    {   positions => [ [ 1, 4, 5 ], [ 3, 2, -10 ] ],
        bbox => [ 1, 2, -10, 3, 4, 5 ],
    },

    {   positions => [ [ 1, 4, 5 ], [ 3, 2, -10 ], [ 6, 6, 7 ] ],
        bbox => [ 1, 2, -10, 6, 6, 7 ],
    },

    # ignore further dimensions
    {   positions => [
            [ 1, 4, 5,   1,  2,  3 ],
            [ 3, 2, -10, 20, 20, -20 ],
            [ 6, 6, 7,   20, 0,  -10 ]
        ],
        bbox => [
            1, 2, -10, 1,  0,  -20,    #
            6, 6, 7,   20, 20, 3
        ],
    },
);

foreach my $test (@tests) {

    is_deeply compute_bbox( $test->{positions} ), $test->{bbox}, "bbox ok";
}

note "compare_positions";

@tests = (
    {   positions => [ [ 1, 2 ], [ 1, 2 ] ],
        result => 1,
    },
    {   positions => [ [ 1, 2 ], [ 2, 2 ] ],
        result => 0,
    },
    {   positions => [ [ 1, 2, 3 ], [ 1, 2, 1 ] ],
        result => 0,
    },
    {   positions => [ [ 1, 2, 3 ], [ 1, 2, 3 ] ],
        result => 1,
    },

    # ignore further dimensions
    {   positions => [ [ 1, 2, 3, 4 ], [ 1, 2, 3, 5 ] ],
        result => 1,
    },
);

foreach my $test (@tests) {
    is compare_positions( @{ $test->{positions} } ), $test->{result},
        "compare_positions ok";
}

done_testing();

