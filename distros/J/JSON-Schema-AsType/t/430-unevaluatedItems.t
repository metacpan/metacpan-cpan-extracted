use Test2::V1 -Pip;

use feature qw/ signatures/;

use JSON::Schema::AsType;
use JSON;

subtest 'unevaluatedProperties on its own' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            'unevaluatedItems' => JSON::false,
            items              => { 'type' => 'string' },
        }
    );

    ok $schema->check( [ 'foo', 'bar' ] ), 'all good';
};

subtest 'if' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            'unevaluatedItems' => JSON::false,
            if                 => { items => [ { const => 'a' } ] }
        }
    );

    ok !$schema->check( ['foo'] );
};

subtest 'recursiveRef' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            '$id' =>
              'https://example.com/unevaluated-items-with-recursive-ref/extended-tree',
            '$schema' => 'https://json-schema.org/draft/2019-09/schema',
            '$recursiveAnchor' => JSON::true
              '$defs' => {
                'tree' => {
                    '$id' =>
                      'https://example.com/unevaluated-items-with-recursive-ref/tree',
                    'type'             => 'array',
                    '$recursiveAnchor' => JSON::true,
                    'items'            => [
                        { 'type' => 'number' },
                        {   '$comment' =>
                              'unevaluatedItems comes first so it\'s more likely to catch bugs with implementations that are sensitive to keyword ordering',
                            'unevaluatedItems' => JSON::false,
                            '$recursiveRef'    => '#'
                        }
                    ],
                }
              },
            '$ref'  => './tree',
            'items' => [ JSON::true, JSON::true, { 'type' => 'string' } ],
        }
    );

    ok $schema->check( [ 1, [ 2, [], 'b' ], 'a' ] );
};

subtest 'not' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => '2019-09',
        schema => {
            'unevaluatedItems' => JSON::false,
            'not'              => {
                'not' => { 'items' => [ JSON::true, { 'const' => 'bar' } ] }
            },
            'items' => [ { 'const' => 'foo' } ]
        }
    );

    ok !$schema->check( [ 'foo', 'bar' ] );
};
done_testing
