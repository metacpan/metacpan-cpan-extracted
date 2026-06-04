use strict;
use warnings;
use lib 't/lib';
use FalkorDBTests qw(get_connection_details);
use Test::More;
use FalkorDB;
use JSON::PP;

my ( $host, $port ) = get_connection_details();
plan tests => 14;

my $db    = FalkorDB->new( host => $host, port => $port );
my $graph = $db->select_graph('test_param_graph');

# Clean up
eval { $graph->delete(); };

# Test helper method directly via class method style or object style
my $serialize = sub { FalkorDB::Graph::_serialize_param( $_[0] ) };

# Basic scalars
is( $serialize->("hello"), '"hello"', 'String parameter quoted' );
is(
    $serialize->("hello \"world\""),
    '"hello \\"world\\""',
    'String parameter double-quotes escaped'
);
is( $serialize->("hello\nworld"),  '"hello\\nworld"', 'String parameter newlines escaped' );
is( $serialize->(42),              '42',              'Integer parameter not quoted' );
is( $serialize->(3.1415),          '3.1415',          'Float parameter not quoted' );
is( $serialize->(JSON::PP::true),  'true',            'JSON::PP::true serialized to true' );
is( $serialize->(JSON::PP::false), 'false',           'JSON::PP::false serialized to false' );
is( $serialize->(undef),           'null',            'undef serialized to null' );

# Nested arrays
is( $serialize->( [ 1, "two", 3.3 ] ), '[1, "two", 3.3]', 'Array serialized correctly' );

# Nested hashes
my $serialized_hash = $serialize->( { name => 'Alice', age => 30 } );

# Map order is not guaranteed, check both possibilities
ok(
    $serialized_hash eq '{name: "Alice", age: 30}'
      || $serialized_hash eq '{age: 30, name: "Alice"}',
    'Hash serialized correctly'
);

# Real database integration
my $res = $graph->query(
    "CREATE (:person {name: \$name, age: \$age, active: \$active, hobbies: \$hobbies})",
    {
        name    => "Bob \\O'Connor\"",
        age     => 28,
        active  => JSON::PP::true,
        hobbies => [ 'hiking', 'cooking' ]
    }
);
is( $res->nodes_created, 1, 'Node created using parameterized query' );

# Read back and verify
my $res_read =
  $graph->query( "MATCH (p:person) WHERE p.name = \$name RETURN p.age, p.active, p.hobbies",
    { name => "Bob \\O'Connor\"" } );
is( $res_read->row_count, 1, 'Found parameterized node' );
my $row = $res_read->get_row(0);
is( $row->[0], 28, 'Age matched' );

# Note: FalkorDB might return list/boolean in standard formats, verify
is_deeply( $row->[2], [ 'hiking', 'cooking' ], 'Array/List property matched' );

# Clean up
$graph->delete();
