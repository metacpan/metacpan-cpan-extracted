use 5.42.0;

use Test2::V1 -Pip;

use JSON::Schema::AsType;

my $remote_url = 'https://localhost:1234/foo';

my $schema = JSON::Schema::AsType->new(
    draft  => 7,
    schema => { '$ref' => $remote_url . '#/definitions/refToInteger' }
);

$schema->register_schema(
    $remote_url => {
        "definitions" => {
            "integer"      => { "type" => "integer" },
            "refToInteger" => { '$ref' => "#/definitions/integer" }
        }
    }
);

is [ $schema->all_schema_uris ] => [
    qw!
      http://254.0.0.1:1/
      https://localhost:1234/foo
      !
];

ok $schema->check(1),         "we accept numbers";
ok !$schema->check('potato'), "... but not strings";

done_testing;
