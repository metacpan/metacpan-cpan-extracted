#!perl
use Modern::Perl;

use Graph::Undirected::Hamiltonicity::Transforms
    qw(&string_to_graph &get_common_neighbors);

use Test::More;

plan tests => 17;

my @test_graphs = (
    {   graph_text =>
            '0=1,0=3,0=9,0=10,1=2,1=4,2=5,2=9,3=4,3=6,4=5,4=7,5=8,6=7,6=10,7=8,8=9,8=10',
        tests => [
            {   vertices                  => [ 0, 1 ],
                expected_common_neighbors => []
            },
            {   vertices                  => [ 0, 2 ],
                expected_common_neighbors => [ 1, 9 ]
            },
            {   vertices                  => [ 0, 3 ],
                expected_common_neighbors => []
            },
            {   vertices                  => [ 0, 4 ],
                expected_common_neighbors => [ 1, 3 ]
            },
            {   vertices                  => [ 0, 6 ],
                expected_common_neighbors => [ 3, 10 ]
            },
            {   vertices                  => [ 0, 8 ],
                expected_common_neighbors => [ 9, 10 ]
            },
            {   vertices                  => [ 4, 6 ],
                expected_common_neighbors => [ 3, 7 ]
            },
        ]
    },

);

foreach my $test_graph (@test_graphs) {
    my $g = string_to_graph( $test_graph->{graph_text} );

    foreach my $test ( @{ $test_graph->{tests} } ) {
        my %actual_common_neighbors =
            %{ get_common_neighbors( $g, @{ $test->{vertices} } ) };

        foreach my $expected_common_neighbor (
            @{ $test->{expected_common_neighbors} } )
        {
            is( $actual_common_neighbors{$expected_common_neighbor},
                1,
                "Found expected common neighbor: $expected_common_neighbor" );

            delete $actual_common_neighbors{$expected_common_neighbor};
        }

        is( int( keys %actual_common_neighbors ),
            0, "Found all common neighbors." );
    }
}

