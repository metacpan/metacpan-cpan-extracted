# FalkorDB Perl Module

A clean, object-oriented Perl client library for FalkorDB (a low-latency graph database built on Redis). It wraps Cypher query execution, handles type serialization for query parameterization, and parses responses into structured Node, Edge, and Path objects.

## Features

- **Standard & Read-Only Queries**: Fully supports `GRAPH.QUERY` and `GRAPH.RO_QUERY`.
- **Query Parameterization**: Automatically serializes complex Perl data types (strings, numbers, booleans, undef/null, arrays, and hashes/maps) into Cypher-compliant parameter syntax.
- **Graph Schema Object Mapping**: Decodes database responses into class instances:
  - `FalkorDB::Node`
  - `FalkorDB::Edge`
  - `FalkorDB::Path`
- **Result Parsing**: Access headers, row arrays, or iterate row-by-row as arrays or column-mapped hashes.
- **Index Management**: Helper methods to create and drop indices.

## File Structure

- [lib/FalkorDB.pm](file:///opt/lib/FalkorDB.pm): Base client connection class.
- [lib/FalkorDB/Graph.pm](file:///opt/lib/FalkorDB/Graph.pm): Graph instance operations, query executions, parameter serialization.
- [lib/FalkorDB/QueryResult.pm](file:///opt/lib/FalkorDB/QueryResult.pm): Helper to parse query results and manage query statistics.
- [lib/FalkorDB/Node.pm](file:///opt/lib/FalkorDB/Node.pm): Graph node representation.
- [lib/FalkorDB/Edge.pm](file:///opt/lib/FalkorDB/Edge.pm): Graph relationship/edge representation.
- [lib/FalkorDB/Path.pm](file:///opt/lib/FalkorDB/Path.pm): Graph traversal path representation.
- [t/](file:///opt/t/): Full test suite checking load, connection, query, parameters, and types.
- [Makefile.PL](file:///opt/Makefile.PL): Packaging specification.

## Synopsis

```perl
use FalkorDB;
use JSON::PP; # For boolean wrappers

# 1. Connect
my $db = FalkorDB->new(
    host => 'falkordb',
    port => 6379,
);

# 2. Select Graph
my $graph = $db->select_graph('SocialNetwork');

# 3. Create Nodes with Parameters
$graph->query(
    "CREATE (:person {name: \$name, age: \$age, active: \$active, hobbies: \$hobbies})",
    {
        name   => "Bob O'Connor",
        age    => 28,
        active => JSON::PP::true,
        hobbies => ['hiking', 'cooking']
    }
);

# 4. Fetch Results
my $res = $graph->query(
    "MATCH (p:person) WHERE p.age = \$age RETURN p.name, p.active, p.hobbies",
    { age => 28 }
);

# Iterate as arrays
while (my $row = $res->next_row()) {
    my ($name, $active, $hobbies) = @$row;
    print "$name is active? $active, hobbies: @$hobbies\n";
}

# Or iterate as hashes
$res->reset_iterator();
while (my $hash = $res->next_hash()) {
    print "Found: ", $hash->{'p.name'}, "\n";
}
```

## Running Tests

Ensure a FalkorDB instance is accessible at `falkordb:6379`, then run:

```bash
perl Makefile.PL
make test
```

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
