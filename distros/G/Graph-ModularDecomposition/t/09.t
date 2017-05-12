# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# test for self loops: looks like they are allowed
# documentation needs to be more explicit about these being allowed

use Test;
BEGIN { plan tests => 1 };
use Graph::ModularDecomposition;

#########################

sub test9 {
    my $g = new Graph::ModularDecomposition;
    $g = $g->add_vertex( 'a' );
    $g = $g->add_edge( 'a', 'a' );
    ok $g, 'a-a';
}


test9;
