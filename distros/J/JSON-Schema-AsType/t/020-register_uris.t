use strict;
use warnings;

use Test2::V1 -Pip;

use JSON::Schema::AsType;
use JSON qw/ from_json /;

my $schema =
  JSON::Schema::AsType->new( draft => 4, schema => from_json <<'JSON' );
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

like [ $schema->all_schema_uris ], bag {
    item 'http://localhost:1234/node';
    item 'http://localhost:1234/tree';
};

ok $schema->check(
    {   meta  => 'root',
        nodes => [
            {   value   => 1,
                subtree => { meta => "child", "nodes" => [] }
            }
        ]
    }
);

done_testing;
