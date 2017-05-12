use strict;
use Test::More tests => 47;
use Graph;

BEGIN { use_ok('Graph::MaxFlow', qw(max_flow)) }

# normal graph (p. 645 of Cormen)
my $g1 = new Graph;
$g1->add_weighted_edge("s",  "v1", 16);
$g1->add_weighted_edge("s",  "v2", 13);
$g1->add_weighted_edge("v1", "v2", 10);
$g1->add_weighted_edge("v1", "v3", 12);
$g1->add_weighted_edge("v2", "v1", 4);
$g1->add_weighted_edge("v2", "v4", 14);
$g1->add_weighted_edge("v3", "v2", 9);
$g1->add_weighted_edge("v3", "t",  20);
$g1->add_weighted_edge("v4", "v3", 7);
$g1->add_weighted_edge("v4", "t",  4);

my $flow1 = max_flow($g1, "s", "t");
check_flow($g1, $flow1, "s", "t", 23);

# bipartite graph (p. 665 of Cormen)
my $b = new Graph;
$b->add_weighted_edge("l1", "r1", 1);
$b->add_weighted_edge("l2", "r1", 1);
$b->add_weighted_edge("l2", "r3", 1);
$b->add_weighted_edge("l3", "r2", 1);
$b->add_weighted_edge("l3", "r3", 1);
$b->add_weighted_edge("l3", "r4", 1);
$b->add_weighted_edge("l4", "r3", 1);
$b->add_weighted_edge("l5", "r3", 1);
$b->add_weighted_edge("s", "l1", 1);
$b->add_weighted_edge("s", "l2", 1);
$b->add_weighted_edge("s", "l3", 1);
$b->add_weighted_edge("s", "l4", 1);
$b->add_weighted_edge("s", "l5", 1);
$b->add_weighted_edge("r1", "t", 1);
$b->add_weighted_edge("r2", "t", 1);
$b->add_weighted_edge("r3", "t", 1);
$b->add_weighted_edge("r4", "t", 1);

my $flow2 = Graph::MaxFlow::max_flow($b, "s", "t");
check_flow($b, $flow2, "s", "t", 3);

sub check_flow {
    my ($g, $flow, $s, $t, $expect) = @_;

    is($g, $flow, "graph structure matches");


    for my $u ($flow->vertices) {
        my $net_flow = 0;
        for my $v ($flow->successors($u)) {
            my $capacity = $g->get_edge_weight($u, $v);
            my $used = $flow->get_edge_weight($u, $v);
            ok($used <= $capacity, "capacity constraint");
            $net_flow += $used;
        }
        for my $v ($flow->predecessors($u)) {
            $net_flow -= $flow->get_edge_weight($v, $u);
        }

        if ($u eq $s) {
            is($net_flow, $expect, "flow out from source");
        } elsif ($u eq $t) {
            is($net_flow, -$expect, "flow in to sink");
        } else {
            is($net_flow, 0, "flow conservation");
        }
    }
}
