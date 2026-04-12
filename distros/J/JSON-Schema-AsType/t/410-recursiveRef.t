use Test2::V1 -Pip;

use JSON::Schema::AsType;
use JSON;

subtest '1' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            '$id' =>
              "http://localhost:4242/draft2019-09/recursiveRef2/schema.json",
            '$schema' => "https://json-schema.org/draft/2019-09/schema",
            '$defs'   => {
                myobject => {
                    '$id'              => "myobject.json",
                    '$recursiveAnchor' => JSON::true,
                    anyOf              => [
                        { type => "string" },
                        {   additionalProperties =>
                              { '$recursiveRef' => "#" },
                            type => "object"
                        }
                    ]
                }
            },
            anyOf =>
              [ { type => "integer" }, { '$ref' => '#/$defs/myobject' } ]
        }
    );

    ok $schema->strict_string, "strict strings on";

    ok !$schema->check(JSON::true), 'boolean is no good';
    ok !$schema->check( { foo => JSON::true } );
    ok !$schema->check( { foo => 1.1 } );
    ok $schema->check( { foo  => 'bueno' } );
};

subtest '2' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            '$id'     => 'https://example.com/recursiveRef8_main.json',
            '$schema' => 'https://json-schema.org/draft/2019-09/schema',

            '$defs' => {
                'inner' => {
                    '$id'                  => 'recursiveRef8_inner.json',
                    '$recursiveAnchor'     => JSON::true,
                    'additionalProperties' => { '$recursiveRef' => '#' },
                }
            },

            'if'   => { 'propertyNames' => { 'pattern' => '^[a-m]' } },
            'then' => {
                '$ref'             => 'recursiveRef8_inner.json',
                '$recursiveAnchor' => JSON::true,
                '$id'              => 'recursiveRef8_anyLeafNode.json',
            },
            'else' => {
                'type'             => [ 'object', 'integer' ],
                '$ref'             => 'recursiveRef8_inner.json',
                '$recursiveAnchor' => JSON::true,
                '$id'              => 'recursiveRef8_integerNode.json'
            },
        }
    );

    is $schema->uri => 'https://example.com/recursiveRef8_main.json';

    is [ grep { /example.com/ } $schema->all_schema_uris ] => [
        "https://example.com/recursiveRef8_anyLeafNode.json",
        "https://example.com/recursiveRef8_inner.json",
        "https://example.com/recursiveRef8_integerNode.json",
        "https://example.com/recursiveRef8_main.json"
      ],
      "we have the right schemas";

    ok scalar @{ [ $schema->all_keywords ] }, 'we have keywords';

    my $else =
      $schema->fetch('https://example.com/recursiveRef8_main.json#/else');

    ok scalar @{ [ $else->all_active_keywords ] }, "else has active keywords";

    ok !$schema->fetch('https://example.com/recursiveRef8_main.json#/else')
      ->check(JSON::true), "booleans are not allowed, directly for the else";
    ok !$schema->fetch('https://example.com/recursiveRef8_main.json#/else')
      ->check(1.1), "floats are not allowed, directly for the else";

    ok !$schema->check( { november => 1.1 } ), "floats are not allowed";
};

done_testing;
