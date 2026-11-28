#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

my @cases =
(
    [ 'A sibling of a reference enforces its type',
        { '$defs' => { base => { properties => { a => { type => 'integer' } } } },
          '$ref' => '#/$defs/base', properties => { extra => { type => 'string' } } },
        { a => 1, extra => 1 }, 0 ],
    [ 'Both references enforce their constraints',
        { '$defs' => { a => { type => 'integer' }, b => { minimum => 2 } },
          '$ref' => '#/$defs/a', '$dynamicRef' => '#/$defs/b' }, 1, 0 ],
    [ 'Both references can succeed',
        { '$defs' => { a => { type => 'integer' }, b => { minimum => 2 } },
          '$ref' => '#/$defs/a', '$dynamicRef' => '#/$defs/b' }, 2, 1 ],
    [ 'Both references contribute object annotations',
        { '$defs' => { a => { properties => { a => JSON::true } }, b => { properties => { b => JSON::true } } },
          '$ref' => '#/$defs/a', '$dynamicRef' => '#/$defs/b', unevaluatedProperties => JSON::false },
        { a => 1, b => 2 }, 1 ],
    [ 'Both references contribute array annotations',
        { '$defs' => { a => { prefixItems => [JSON::true] }, b => { contains => { const => 2 } } },
          '$ref' => '#/$defs/a', '$dynamicRef' => '#/$defs/b', unevaluatedItems => JSON::false },
        [1, 2], 1 ],
    [ 'Reference and local property annotations are combined',
        { '$defs' => { a => { properties => { a => JSON::true } } }, '$ref' => '#/$defs/a',
          properties => { b => JSON::true }, unevaluatedProperties => JSON::false }, { a => 1, b => 2 }, 1 ],
    [ 'Unknown properties are still forbidden',
        { '$defs' => { a => { properties => { a => JSON::true } } }, '$ref' => '#/$defs/a',
          properties => { b => JSON::true }, unevaluatedProperties => JSON::false }, { a => 1, b => 2, c => 3 }, 0 ],
    [ 'A sibling of a dynamic reference is enforced',
        { '$defs' => { a => { type => 'integer' } }, '$dynamicRef' => '#/$defs/a', minimum => 2 }, 1, 0 ],
    [ 'A false dynamic reference cannot be bypassed',
        { '$defs' => { a => JSON::true, b => JSON::false }, '$ref' => '#/$defs/a', '$dynamicRef' => '#/$defs/b' }, 1, 0 ],
    [ 'A false reference cannot be bypassed',
        { '$defs' => { a => JSON::false, b => JSON::true }, '$ref' => '#/$defs/a', '$dynamicRef' => '#/$defs/b' }, 1, 0 ],
    [ 'A pure reference still works',
        { '$defs' => { a => { type => 'integer' } }, '$ref' => '#/$defs/a' }, 1, 1 ],
    [ 'A recursive reference still enforces its sibling',
        { '$id' => 'https://example.test/node', '$dynamicAnchor' => 'node', type => 'object',
          properties => { next => { '$dynamicRef' => '#node', minProperties => 1 }, value => { type => 'integer' } } },
        { next => {} }, 0 ],
    [ 'A recursive reference with valid siblings succeeds',
        { '$id' => 'https://example.test/node', '$dynamicAnchor' => 'node', type => 'object',
          properties => { next => { '$dynamicRef' => '#node', minProperties => 1 }, value => { type => 'integer' } } },
        { next => { value => 1 } }, 1 ],
);

for my $compile (0, 1)
{
    for my $case ( @cases )
    {
        my( $name, $schema, $data, $expected ) = @$case;
        my $js = JSON::Schema::Validate->new( $schema, compile => $compile );
        is( $js->validate( $data ) ? 1 : 0, $expected, "compile=$compile: $name" );
    }
}

done_testing;

__END__
