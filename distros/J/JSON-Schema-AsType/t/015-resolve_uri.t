use 5.42.0;

use Test2::V1 -Pip;

use experimental qw/ refaliasing /;

use JSON::Schema::AsType::Registry;
use JSON::Schema::AsType;

*resolve_uri = *JSON::Schema::AsType::Registry::_resolve_uri;

my @cases = (
    [ ['http://foo.com/bar'], 'http://foo.com/bar', "just the url" ],
    [   [ 'http://foo.com/bar', 'http://other.com' ], 'http://foo.com/bar',
        "absolute"
    ],
    [ [ '/bar', 'http://other.com' ], 'http://other.com/bar', "relative" ],
    [ [ '#/this/that', 'http://other.com' ], 'http://other.com/#/this/that' ],
    [   [ '#/this/that', 'http://other.com/#/elsewhere' ],
        'http://other.com/#/this/that'
    ],
    [   [ '#./this/that', 'http://other.com/#/elsewhere' ],
        'http://other.com/#/elsewhere/this/that',
        'relative fragment'
    ],
    [   [ 'node', 'http://localhost:1234/tree#/properties/nodes/items' ] =>
          'http://localhost:1234/node'
    ],
    [   [ '#', 'http://localhost:1234/tree#/properties/nodes/items' ] =>
          'http://localhost:1234/tree'
    ],
);

is resolve_uri( $_->[0]->@* ) => $_->[1],
  $_->[2] // join ' + ', $_->[0]->@*
  for @cases;

subtest recursive => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => 7,
        schema => {
            anyOf => [
                { type => 'string' },
                {   type       => 'object',
                    properties => { 'nah' => { '$ref' => '#' } }
                }
            ]
        }
    );

    ok $schema->check('batman');
    ok $schema->type;
    ok !$schema->check( [] );
    ok $schema->check( { nah => 'batman' } );
    ok $schema->check( { nah => { nah => 'batman' } } );

};

subtest 'ids for draft4' => sub {
    my $schema = JSON::Schema::AsType->new(
        draft  => 4,
        schema => {
            "id"          => "http://localhost:1234/scope_change_defs1.json",
            "type"        => "object",
            "properties"  => { "list" => { '$ref' => "#/definitions/baz" } },
            "definitions" => {
                "baz" => {
                    "id"   => "folder/",
                    "type" => "array",
                    items  => { '$ref' => 'folderInteger.json' }
                }
            }
        }
    );

    $schema->register_schema(
        'http://localhost:1234/folder/folderInteger.json',
        { type => 'integer' } );

    is $schema->registered_schema('http://localhost:1234/folder/')->uri =>
      'http://localhost:1234/folder/';

    ok $schema->check( { list  => [ 1, 2, 3 ] } );
    ok !$schema->check( { list => [ 1, 2, 'potato' ] } );

};

done_testing;
