use strict;
use warnings;
use Test::More;
use Test::Snapshot;

use GraphViz2::Parse::ISA;

my $g_isa = GraphViz2::Parse::ISA->new;
unshift @INC, 't/lib';
$g_isa->add(class => 'Adult::Child::Grandchild', ignore => []);
$g_isa->add(class => 'HybridVariety', ignore => []);
$g_isa->generate_graph;

my $g = $g_isa->graph;
is_deeply_snapshot $g->node_hash, 'nodes isa';
is_deeply_snapshot $g->edge_hash, 'edges isa';

done_testing;
