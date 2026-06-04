use strict;
use warnings;
use lib 't/lib';
use FalkorDBTests qw(get_connection_details);
use Test::More;
use FalkorDB;

my ( $host, $port ) = get_connection_details();
plan tests => 22;

my $db    = FalkorDB->new( host => $host, port => $port );
my $graph = $db->select_graph('test_types_graph');

# Clean up
eval { $graph->delete(); };

# Create a small graph
$graph->query(
"CREATE (:person {id_num: 1, name: 'Alice'})-[:knows {since: 2015}]->(:person {id_num: 2, name: 'Bob'})"
);

# Test Node retrieval
my $res = $graph->query("MATCH (p:person {name: 'Alice'}) RETURN p");
is( $res->row_count, 1, 'One row returned for Node query' );
my $row  = $res->get_row(0);
my $node = $row->[0];
isa_ok( $node, 'FalkorDB::Node' );
ok( defined( $node->id ), 'Node has internal ID' );
is_deeply( $node->labels, ['person'], 'Node label matches' );
is( $node->property('name'),   'Alice', 'Node property name matches' );
is( $node->property('id_num'), 1,       'Node property id_num matches' );

# Test Edge retrieval
my $res_edge = $graph->query("MATCH ()-[r:knows]->() RETURN r");
is( $res_edge->row_count, 1, 'One row returned for Edge query' );
my $row_edge = $res_edge->get_row(0);
my $edge     = $row_edge->[0];
isa_ok( $edge, 'FalkorDB::Edge' );
ok( defined( $edge->id ), 'Edge has internal ID' );
is( $edge->type, 'knows', 'Edge type matches' );
ok( defined( $edge->src_node ),  'Edge has src_node ID' );
ok( defined( $edge->dest_node ), 'Edge has dest_node ID' );
is( $edge->property('since'), 2015, 'Edge property since matches' );

# Test Path retrieval
my $res_path = $graph->query("MATCH path = (a:person)-[r:knows]->(b:person) RETURN path");
is( $res_path->row_count, 1, 'One row returned for Path query' );
my $row_path = $res_path->get_row(0);
my $path     = $row_path->[0];
isa_ok( $path, 'FalkorDB::Path' );

# Verify path nodes and edges
my $nodes    = $path->nodes();
my $edges    = $path->edges();
my $elements = $path->elements();

is( scalar @$nodes,    2, 'Path contains exactly 2 nodes' );
is( scalar @$edges,    1, 'Path contains exactly 1 edge' );
is( scalar @$elements, 3, 'Path contains exactly 3 elements in sequence' );

is( $elements->[0]->{type}, 'node', 'First element in sequence is a node' );
is( $elements->[1]->{type}, 'edge', 'Second element in sequence is an edge' );
is( $elements->[2]->{type}, 'node', 'Third element in sequence is a node' );

is( $elements->[0]->{id}, $nodes->[0], 'First sequence ID matches first node ID' );

# Clean up
$graph->delete();
