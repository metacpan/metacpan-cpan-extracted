# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# test strongly_connected_components of disconnected graph
# looks very broken in Graph-0.20102: one null component???
# expecting gd to be same as g, but instead gd has 1 null vertex
# fine with my patches, now in -0.20103

use Test;
BEGIN { plan tests => 3 };
use Graph::ModularDecomposition;

#########################

sub test11 {
    my $g = new Graph::ModularDecomposition;
    $g = $g->add_vertex( 'a' );
    $g = $g->add_vertex( 'b' );
    my $gd = $g->strongly_connected_graph;
    ok $g, $gd;
    ok $gd, 'a,b';
    ok join('', sort $g->vertices), join('', sort $gd->vertices);
}


test11;
