#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Graph::Weighted';

my $weight_dataset = [
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

my $n = 0;
for my $data (@$weight_dataset) {
    my $g = Graph::Weighted->new();
    isa_ok $g, 'Graph::Weighted', "weight $n";

    $g->populate($data);

    my $g_weight = 0;
    for my $vertex ($g->vertices()) {
        $g_weight += $g->get_cost($vertex);
    }
    my $w = _weight_of($data);
    is $g_weight, $w, "vertex weight: $g_weight = $w";

    for my $e ($g->edges) {
        my $w = $g->get_cost($e, 'weight');
        ok defined($w), "edge attributes: @$e = $w";
    }

    $n++;
}

my $g = Graph::Weighted->new();
isa_ok $g, 'Graph::Weighted';
$g->populate($weight_dataset->[-1]);
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
is( $weight, undef, 'path_cost' );

$g = Graph::Weighted->new();
$g->populate(
    {
        0 => { label => 'A', 3 => 0.2, 1 => 0.8 },
    },
);
is $g->get_vertex_attribute( 0, 'label' ), 'A', 'get_vertex_attribute 0 label';

done_testing();

sub _weight_of {
    my $data = shift;
    my $weight = 0;
    for my $i (@$data) {
        $weight += $_ for @$i;
    }
    return $weight;
}
