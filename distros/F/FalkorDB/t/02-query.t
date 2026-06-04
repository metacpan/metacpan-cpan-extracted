use strict;
use warnings;
use lib 't/lib';
use FalkorDBTests qw(get_connection_details);
use Test::More;
use FalkorDB;

my ( $host, $port ) = get_connection_details();
plan tests => 22;

my $db         = FalkorDB->new( host => $host, port => $port );
my $graph_name = 'test_query_graph';

# Clean up graph if it exists
eval { $db->delete_graph($graph_name); };

my $graph = $db->select_graph($graph_name);

# Test write query (Create nodes)
my $res = $graph->query("CREATE (:actor {name: 'Keanu Reeves', age: 55})");
isa_ok( $res, 'FalkorDB::QueryResult' );
is( $res->nodes_created,  1, 'One node created' );
is( $res->properties_set, 2, 'Two properties set' );
is( $res->labels_added,   1, 'One label added' );

# Test write query (Create another node and a relationship)
$res = $graph->query("CREATE (:movie {title: 'The Matrix'})");
is( $res->nodes_created, 1, 'Movie node created' );

my $res_rel =
  $graph->query( "MATCH (a:actor {name: 'Keanu Reeves'}), (m:movie {title: 'The Matrix'}) "
      . "CREATE (a)-[r:acted_in {role: 'Neo'}]->(m) RETURN r" );
is( $res_rel->relationships_created, 1, 'Relationship created' );
is( $res_rel->properties_set,        1, 'One relationship property set' );

# Test read query (Retrieve data)
my $res_read =
  $graph->query("MATCH (a:actor)-[r:acted_in]->(m:movie) RETURN a.name, r.role, m.title");
is( $res_read->row_count, 1, 'One row returned' );
is_deeply( $res_read->header, [ 'a.name', 'r.role', 'm.title' ], 'Headers match' );

# Test row fetching
my $row = $res_read->get_row(0);
ok( ref $row eq 'ARRAY', 'get_row returns array ref' );
is( $row->[0], 'Keanu Reeves', 'First column value matches' );
is( $row->[1], 'Neo',          'Second column value matches' );
is( $row->[2], 'The Matrix',   'Third column value matches' );

# Test next_row iterator
$res_read->reset_iterator();
my $row_iter = $res_read->next_row();
is( $row_iter->[0], 'Keanu Reeves', 'next_row works' );
ok( !defined( $res_read->next_row() ), 'next_row returns undef at end' );

# Test hash fetching
my $hashes = $res_read->hashes();
is( scalar @$hashes,          1,              'One hash returned' );
is( $hashes->[0]->{'a.name'}, 'Keanu Reeves', 'Hash key a.name matches' );
is( $hashes->[0]->{'r.role'}, 'Neo',          'Hash key r.role matches' );

# Test next_hash iterator
$res_read->reset_iterator();
my $hash_iter = $res_read->next_hash();
is( $hash_iter->{'m.title'}, 'The Matrix', 'next_hash works' );
ok( !defined( $res_read->next_hash() ), 'next_hash returns undef at end' );

# Test ro_query
my $res_ro = $graph->ro_query("MATCH (a:actor) RETURN a.name");
is( $res_ro->row_count, 1, 'ro_query returned 1 row' );

# Clean up
my $deleted = $graph->delete();
ok( $deleted, 'Graph deleted successfully' );
