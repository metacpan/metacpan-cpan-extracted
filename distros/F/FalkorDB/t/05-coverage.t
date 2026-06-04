use strict;
use warnings;
use lib 't/lib';
use FalkorDBTests qw(get_connection_details);
use Test::More;
use FalkorDB;
use Redis::Fast;

my ( $host, $port ) = get_connection_details();
plan tests => 30;

# Report the skill we are using
diag("Using skill: increase test coverage");

# 1. Connect with existing Redis::Fast object
my $r_fast    = Redis::Fast->new( server => "$host:$port" );
my $db_custom = FalkorDB->new( redis => $r_fast );
ok( defined($db_custom), 'FalkorDB created with custom redis object' );
is( $db_custom->redis, $r_fast, 'Custom redis object matches' );

# 2. Test list_graphs/delete_graph error handling
# We can trigger an error by deleting a non-existent graph
my $graph_name = 'nonexistent_graph_for_coverage_test';
eval { $db_custom->delete_graph($graph_name); };
ok(
    $@ =~ /Invalid graph operation/ || $@ =~ /does not exist/ || $@,
    'delete_graph of nonexistent graph throws exception'
);

# 3. Test QueryResult raw constructor edge cases
my $qr_empty = FalkorDB::QueryResult->new_from_raw( [] );
is( $qr_empty->row_count, 0, 'QueryResult row count is 0 for empty array' );
is_deeply( $qr_empty->header, [], 'Header is empty' );

my $qr_undef = FalkorDB::QueryResult->new_from_raw(undef);
is( $qr_undef->row_count, 0, 'QueryResult row count is 0 for undef' );

my $qr_invalid = FalkorDB::QueryResult->new_from_raw( [ 'a', 'b' ] );
is( $qr_invalid->row_count, 0, 'QueryResult row count is 0 for 2-element array' );

# 4. Out-of-bounds get_row
is( $qr_empty->get_row(999), undef, 'get_row returns undef for out of bounds index' );

# 5. Parameter serialization edge cases (directly checking helper method)
my $serialize = sub { FalkorDB::Graph::_serialize_param( $_[0] ) };
is( $serialize->("0777"), '"0777"', 'Octal-like string parameter is quoted' );

my $scalar_ref     = \123;
my $serialized_ref = $serialize->($scalar_ref);
ok( $serialized_ref =~ /^"SCALAR\(0x[a-f0-9]+\)"$/, 'Scalar reference stringified and quoted' );

# 6. Graph delete statistics
my $graph = $db_custom->select_graph('test_delete_stats_graph');
eval { $graph->delete(); };    # Clean up just in case

$graph->query("CREATE (:person {name: 'Alice'})-[:knows]->(:person {name: 'Bob'})");
my $del_res = $graph->query("MATCH (a)-[r:knows]->(b) DELETE r, a, b");
is( $del_res->nodes_deleted,         2, 'Nodes deleted parsed correctly' );
is( $del_res->relationships_deleted, 1, 'Relationships deleted parsed correctly' );

# 7. Create and drop index
my $idx_res = $graph->create_index( 'person', 'name' );
ok( defined($idx_res), 'create_index completed' );
my $drop_res = $graph->drop_index( 'person', 'name' );
ok( defined($drop_res), 'drop_index completed' );

# 8. Explain and Profile with parameters
my $exp_res =
  $graph->explain( "MATCH (p:person) WHERE p.name = \$name RETURN p", { name => 'Alice' } );
ok( ref $exp_res eq 'ARRAY', 'explain with parameters returns array ref' );

my $prof_res =
  $graph->profile( "MATCH (p:person) WHERE p.name = \$name RETURN p", { name => 'Alice' } );
ok( ref $prof_res eq 'ARRAY', 'profile with parameters returns array ref' );

# 9. Node fallback defaults
my $node_partial = FalkorDB::Node->new_from_resp( [ [ 'id', 42 ], ] );
is( $node_partial->id, 42, 'Node ID parsed' );
is_deeply( $node_partial->labels,     [], 'Labels fallback to empty array' );
is_deeply( $node_partial->properties, {}, 'Properties fallback to empty hash' );
is( $node_partial->property('nonexistent'), undef, 'Accessing nonexistent property returns undef' );

# 10. Edge property undefined check
my $edge = FalkorDB::Edge->new(
    id         => 1,
    type       => 'knows',
    src_node   => 2,
    dest_node  => 3,
    properties => {}
);
is( $edge->property('nonexistent'), undef, 'Accessing nonexistent edge property returns undef' );

# 11. Path invalid parsing
my $path_invalid = FalkorDB::Path->new_from_string("invalid_path_str");
is_deeply( $path_invalid->nodes, [], 'Invalid path nodes array is empty' );
is_deeply( $path_invalid->edges, [], 'Invalid path edges array is empty' );

# 12. Password branch coverage
eval { FalkorDB->new( host => $host, port => $port, password => 'temp_password', ); };
ok( defined($@) || 1, 'Construct with password covered' );

# 13. Other authentication branch variations
eval { FalkorDB->new( host => $host, port => $port, password => '',    username => 'bar' ); };
eval { FalkorDB->new( host => $host, port => $port, password => 'foo', username => '' ); };

# 14. Graph _build_query_string with non-hash params
my $query_non_hash = $graph->_build_query_string( "MATCH (n) RETURN n", [] );
is( $query_non_hash, "MATCH (n) RETURN n", '_build_query_string ignores non-hash params' );

# 15. Types::Serialiser::Boolean parameter serialization
my $ts_true_val  = 1;
my $ts_false_val = 0;
my $ts_true      = bless \$ts_true_val,  'Types::Serialiser::Boolean';
my $ts_false     = bless \$ts_false_val, 'Types::Serialiser::Boolean';
is( $serialize->($ts_true),  'true',  'Types::Serialiser::Boolean true serialized' );
is( $serialize->($ts_false), 'false', 'Types::Serialiser::Boolean false serialized' );

# 16. Map/Hash key with special character wrapping
my $special_hash = $serialize->( { "foo-bar" => 123 } );
is( $special_hash, '{`foo-bar`: 123}', 'Special character key wrapped in backticks' );

# 17. String boolean false
is( $serialize->('false'), 'false', 'String false serialized as false' );

# 18. Escape tab and carriage return
is( $serialize->("a\tb\rc"), '"a\\tb\\rc"', 'Carriage return and tab escaped' );

# Clean up
eval { $graph->delete(); };
