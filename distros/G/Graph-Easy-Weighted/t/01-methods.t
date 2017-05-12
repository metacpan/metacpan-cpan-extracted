#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Graph::Easy::Weighted';

my $dataset = [
    [],                      # No nodes
    [[]],                    # "
    [ [ 0 ], ],              # 1 node, no edges
    [ [ 1, 0, ],             # 2 nodes of "self-edges"
      [ 0, 1, ], ],
    [ [ 0, 1, 2, 0, 0, ],    # 0 talks to 1 once and 2 twice (weight 3)
      [ 1, 0, 3, 0, 0, ],    # 1 talks to 0 once and 2 thrice (weight 4)
      [ 2, 3, 0, 0, 0, ],    # 2 talks to 0 twice and 1 thrice (weight 5)
      [ 0, 0, 1, 0, 0, ],    # 3 talks to 2 once (weight 1)
      [ 0, 0, 0, 0, 0, ], ], # 4 talks to no-one (weight 0)
];

for my $data (@$dataset) {
    my $g = Graph::Easy::Weighted->new();
    isa_ok $g, 'Graph::Easy::Weighted';

    $g->populate($data);

    my $g_weight = 0;
    for my $vertex ($g->vertices()) {
        $g_weight += $g->get_cost($vertex, 'weight');
    }
    my $w = _weight_of($data);
    is $g_weight, $w, "vertex weight: $g_weight = $w";

    for my $e ($g->edges) {
        my $w = $g->get_cost($e, 'weight');
        ok defined($w), 'edge attribute defined';
    }
}

my $g = Graph::Easy::Weighted->new();
isa_ok $g, 'Graph::Easy::Weighted';
$g->populate($dataset->[-1]);
my ($x, $y) = $g->vertex_span();
cmp_ok( $x->[0], '==', 4, 'vertex_span lightest' );
cmp_ok( $y->[0], '==', 2, 'vertex_span heaviest' );

($x, $y) = $g->edge_span();
is_deeply( $x, [ [0,1],[1,0],[3,2] ], 'edge_span lightest' );
is_deeply( $y, [ [1,2],[2,1] ], 'edge_span heaviest' );

my $weight = $g->path_cost( [ 0, 1 ] );
cmp_ok( $weight, '==', 1, 'path_cost' );
$weight = $g->path_cost( [ 0, 1, 2 ] );
cmp_ok( $weight, '==', 4, 'path_cost' );
$weight = $g->path_cost( [ 0, 1, 2, 0 ] );
cmp_ok( $weight, '==', 6, 'path_cost' );
$weight = $g->path_cost( [ 0, 4 ] );
is( $weight, 0, 'path_cost' );

done_testing();

sub _weight_of {
    my $data = shift;
    my $weight = 0;
    for my $i (@$data) {
        $weight += $_ for @$i;
    }
    return $weight;
}
