use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep;

use JSON::Schema::AsType;
use JSON qw/ from_json /;

my $schema = JSON::Schema::AsType->new( schema => from_json  <<'JSON' );
{
    "id": "http://localhost:1234/tree",
    "description": "tree of nodes",
    "type": "object",
    "properties": {
        "meta": {"type": "string"},
        "nodes": {
            "type": "array",
            "items": {"$ref": "node"}
        }
    },
    "required": ["meta", "nodes"],
    "definitions": {
        "node": {
            "id": "http://localhost:1234/node",
            "description": "node",
            "type": "object",
            "properties": {
                "value": {"type": "number"},
                "subtree": {"$ref": "tree"}
            },
            "required": ["value"]
        }
    }
}
JSON

$schema->type;

cmp_deeply [ $schema->all_schema_uris ], bag(
    qw'
        http://json-schema.org/draft-04/schema
        http://localhost:1234/node
        http://localhost:1234/tree
    '
);

#die $schema->registered_schema('http://localhost:1234/node')->type;

ok $schema->check({
        meta => 'root',
        nodes => [ {
            value  => 1,
            subtree => { meta => "child", "nodes" => [ ] }
        }]
});

#diag explain $schema->all_schemas;
