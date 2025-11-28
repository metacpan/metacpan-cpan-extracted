use strict;
use warnings;

use Graph::Undirected;
use Graph::VF2 qw( matches );
use Test::More tests => 2;

my $g1 = Graph::Undirected->new;

$g1->add_edge(0, 6);
$g1->add_edge(0, 7);
$g1->add_edge(1, 5);
$g1->add_edge(1, 7);
$g1->add_edge(2, 4);
$g1->add_edge(2, 5);
$g1->add_edge(2, 6);
$g1->add_edge(3, 4);

my $g2 = Graph::Undirected->new;

$g2->add_edge(0, 6);
$g2->add_edge(0, 8);
$g2->add_edge(1, 5);
$g2->add_edge(1, 7);
$g2->add_edge(2, 4);
$g2->add_edge(2, 7);
$g2->add_edge(2, 8);
$g2->add_edge(3, 4);
$g2->add_edge(3, 5);
$g2->add_edge(3, 6);

is scalar matches( $g1, $g2 ), 8;

my $g3 = Graph::Undirected->new;

for my $edge ($g2->edges) {
    $g3->add_edge(8 - $edge->[0], 8 - $edge->[1]);
}

is scalar matches( $g1, $g3 ), 8;
