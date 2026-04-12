use 5.42.0;
use warnings;

use Test2::V1 -Pip;

use feature qw/ signatures/;

use JSON::Schema::AsType;
use JSON;

my %registry = (
    "http://localhost:1234/draft2019-09/metaschema-no-validation.json",
    JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            '$schema' => "https://json-schema.org/draft/2019-09/schema",
            '$id'     =>
              "http://localhost:1234/draft2019-09/metaschema-no-validation.json",
            '$vocabulary' => {
                "https://json-schema.org/draft/2019-09/vocab/applicator" =>
                  JSON::true,
                "https://json-schema.org/draft/2019-09/vocab/core" =>
                  JSON::true
            },
            '$recursiveAnchor' => JSON::true,
            'allOf'            => [
                {   '$ref' =>
                      "https://json-schema.org/draft/2019-09/meta/applicator"
                },
                {   '$ref' =>
                      "https://json-schema.org/draft/2019-09/meta/core"
                }
            ]
        }
    )

);

subtest basic => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            '$id'     => "https://schema/using/no/validation",
            '$schema' =>
              "http://localhost:1234/draft2019-09/metaschema-no-validation.json",
            properties => { number => { minimum => 10 }, }
        },
        registry => {%registry}
    );

    ok $schema->check( { type => 'string' } ), 'all good';

    ok $schema->check( { number => 1 } ), 'no validation';
};

done_testing;
