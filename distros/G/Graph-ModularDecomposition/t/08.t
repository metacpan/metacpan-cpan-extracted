# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# test that sink_vertices and delete_vertices work together OK
# unfortunately Graph::Directed uses sink to mean "node with no
# successors, but with at least one predecessor" instead of just "node
# with no successors"

use Test;
BEGIN { plan tests => 5 };
use Graph::ModularDecomposition;

#########################

sub test8 {
    my $g = new Graph::ModularDecomposition;
    $g = $g->add_edge( 'jk', 'l' );
    my @f;

    ok $g, 'jk-l';
    @f = $g->sink_vertices;
    ok join( '+', @f ), 'l';
    $g = $g->delete_vertices( @f );

    ok $g, 'jk';
    @f = $g->sink_vertices;
#    ok join( '+', @f ), 'jk';
    ok join( '+', @f ), '';
    $g = $g->delete_vertices( @f );

#    ok $g, '';
    ok $g, 'jk';
}


test8;
