# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# check various inherited functions

use Test;
BEGIN { plan tests => 13 };
use Graph::ModularDecomposition;

#########################

my $g = new Graph::ModularDecomposition;
$g->add_vertex( 'a' );
ok 1;
ok $g->TransitiveClosure_Floyd_Warshall, 'a-a';
ok $g->APSP_Floyd_Warshall, 'a-a';
ok $g->strongly_connected_graph, 'a';
ok $g->copy, 'a';
ok $g->complete, '';

$g->add_edges( qw(a b b c) );
ok $g->TransitiveClosure_Floyd_Warshall, 'a-a,a-b,a-c,b-b,b-c,c-c';
if ( $Graph::VERSION > 0.20105 ) {
    ok $g->APSP_Floyd_Warshall, 'a-a,a-b,a-c,b-b,b-c,c-c';
} else {
    ok $g->APSP_Floyd_Warshall, 'a-a,b-b,c-c';
}
ok $g->strongly_connected_graph, 'a-b,b-c';
ok $g->TransitiveClosure_Floyd_Warshall->strongly_connected_graph,
    'a-b,a-c,b-c';
ok $g->copy, 'a-b,b-c';
ok $g->complete, 'a-b,a-c,b-a,b-c,c-a,c-b';

$g->add_vertex( 'd' );
ok $g->TransitiveClosure_Floyd_Warshall, 'a-a,a-b,a-c,b-b,b-c,c-c,d-d';

exit;

