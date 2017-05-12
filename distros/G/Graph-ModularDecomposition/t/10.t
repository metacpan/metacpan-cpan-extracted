# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# test for empty graph
# seems fine, perhaps the problem is strongly_connected_graph again?

use Test;
BEGIN { plan tests => 4 };
use Graph::ModularDecomposition;

#########################

sub test10 {
    my $g = new Graph::ModularDecomposition;
    $g = $g->add_edge( 'ac', 'b' );
    ok $g, 'ac-b';
    $g = $g->delete_vertices( ( 'b' ) );
    ok $g, 'ac';
    $g = $g->delete_vertices( ( 'ac' ) );
    ok $g, '';
    ok $g->vertices == 0;
}


test10;
