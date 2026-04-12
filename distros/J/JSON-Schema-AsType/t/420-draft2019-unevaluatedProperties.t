use Test2::V1 -Pip;

use feature qw/ signatures/;

use JSON::Schema::AsType;
use JSON::Schema::AsType::Annotations;
use JSON;

subtest 'unevaluatedProperties on its own' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            '$schema' => 'https://json-schema.org/draft/2019-09/schema',
            'unevaluatedProperties' => {
                'minLength' => 3,
                'type'      => 'string'
            },
            'type' => 'object'
        }
    );

    ok !$schema->check( { foo => 'fo' } ), 'fo is too short';
};

subtest 'unevaluatedProperties with adjacent properties' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            'unevaluatedProperties' => JSON::false,
            'type'                  => 'object',
            properties              => { foo => { type => 'string' } }
        }
    );

    ok $schema->check( { foo => 'foo' } ), 'nothing unevaluated';

    #	diag $schema->validate_explain({foo => 'foo'})->@*;
};

subtest 'invalid unevaluatedProperties' => sub {

    ok !keys annotations()->%*, 'empty scope';

    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            'unevaluatedProperties' => { type => 'string', minLength => 3 },
            'type'                  => 'object',
        }
    );

    ok !$schema->check( { foo => 'fo' } ), 'fo is too short';

    #	diag $schema->validate_explain({foo => 'foo'})->@*;
};

subtest 'unevaluatedProperties with adjacent patternProperties' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            'unevaluatedProperties' => JSON::false,
            'type'                  => 'object',
            patternProperties       => { '^foo' => { type => 'string' } }
        }
    );

    ok $schema->check( { foo => 'foo' } ), 'nothing unevaluated';
};

subtest 'unevaluatedProperties with adjacent additionalProperties' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            'unevaluatedProperties' => JSON::false,
            additionalProperties    => JSON::true,
            'type'                  => 'object',
        }
    );

    ok $schema->check( { foo => 'foo' } ), 'nothing unevaluated';
};

subtest 'allOf keeps the scope' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            properties            => { foo => { type => 'string' } },
            unevaluatedProperties => JSON::false,
            type                  => 'object',
            allOf => [ { properties => { bar => { type => 'string' } } } ]
        }
    );

    ok $schema->check( { foo => 'foo', bar => 'bar' } ),
      'nothing unevaluated';
};

subtest 'anyOf' => sub {

    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            'unevaluatedProperties' => JSON::false,
            'type'                  => 'object',
            'properties'            => { 'foo' => { 'type' => 'string' } },
            'anyOf'                 => [
                map {
                    +{  'required'   => ['bar'],
                        'properties' => { 'bar' => { 'const' => 'bar' } }
                     }
                  } qw/ bar baz quux/
            ],

        }
    );

    ok $schema->check( { foo => 'foo', bar => 'bar' } ),
      'catch the bar in anyOf';

};

subtest 'if/then/else' => sub {

    my $props = sub($p) {
        +{  properties => { $p => { type => 'string' } },
            required   => [$p],
         };
    };

    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            'unevaluatedProperties' => JSON::false,
            'type'                  => 'object',
            if   => { properties => { foo => { const => 'then' } } },
            then => $props->('bar')

        }
    );

    ok $schema->check( { foo => 'then', bar => 'bar' } ), 'if/then';

};

done_testing;
