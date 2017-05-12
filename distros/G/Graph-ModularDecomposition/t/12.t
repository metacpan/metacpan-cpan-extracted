# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# check tree_to_string

use Test;
BEGIN { plan tests => 6 };
use Graph::ModularDecomposition qw( tree_to_string );

#########################

ok tree_to_string( {} ), '';

my $g = new Graph::ModularDecomposition;
ok tree_to_string( $g->modular_decomposition_EGMS ), '';
eval {
    open(STDERR, ">/dev/null") if -w '/dev/null';
    $g->debug(3);
    ok tree_to_string( $g->modular_decomposition_EGMS ), '';
    $g->debug(0);
};

$g->add_edge( 'a', 'c' );
$g->add_edge( 'a', 'd' );
$g->canonical_form(1);
# string representation of tree is somewhat nondeterministic
ok(tree_to_string( $g->modular_decomposition_EGMS ),
    qr/linear\[[acd|][acd|][acd|][acd]?\]\(.*complete_0\[..\]\(\[.\];\[.\]\)/);

ok $g->canonical_form(), 1;
Graph::ModularDecomposition->debug(1);
$g->add_edge( 'b', 'd' );
# string representation of tree is somewhat nondeterministic
ok(tree_to_string( $g->modular_decomposition_EGMS ),
    qr/primitive\[....\]\(\[.\];\[.\];\[.\];\[.\]\)/);

