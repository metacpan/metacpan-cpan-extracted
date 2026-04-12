use 5.42.0;

use Test2::V1 -Pip;

use Path::Tiny;
use JSON::Schema::AsType;
use JSON;

subtest 'nested refs' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => 4,
        schema => {
            "definitions" => {
                "a" => { "type" => "integer" },
                "b" => { '$ref' => "#/definitions/a" },
                "c" => { '$ref' => "#/definitions/b" }
            },
            '$ref' => "#/definitions/a"
        }
    );

    # had a weeeeird Integer bug where the first
    # check would fail and the second one work...
    ok $schema->check(2);
    ok $schema->check(2);

};

subtest 'remote refs' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => 4,
        schema => {
            '$ref' =>
              "http://localhost:1234/subSchemas.json#/definitions/integer"
        }
    );

    $schema->register_schema(
        "http://localhost:1234/subSchemas.json" => decode_json path(
            './t/json-schema-test-suite/remotes/draft4/subSchemas.json')
          ->slurp );

    ok $schema->check(1);

};

done_testing;
