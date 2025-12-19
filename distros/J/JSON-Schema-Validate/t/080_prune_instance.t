#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

# Basic pruning with properties + additionalProperties:false
subtest 'prune_instance with properties and additionalProperties:false' => sub
{
    my $schema =
    {
        type       => 'object',
        properties =>
        {
            foo => { type => 'integer' },
            bar => { type => 'string'  },
        },
        additionalProperties => JSON::false,
    };

    my $jsv = JSON::Schema::Validate->new( $schema );

    my $instance =
    {
        foo    => 1,
        bar    => 'ok',
        baz    => 42,
        nested => { x => 1, 'y' => 2 },
    };

    my $pruned = $jsv->prune_instance( $instance );

    is_deeply(
        $instance,
        {
            foo    => 1,
            bar    => 'ok',
            baz    => 42,
            nested => { x => 1, 'y' => 2 },
        },
        'original instance is not modified'
    );

    is_deeply(
        $pruned,
        {
            foo => 1,
            bar => 'ok',
        },
        'unknown properties removed when additionalProperties is false'
    );
};

# patternProperties and additionalProperties:false
subtest 'patternProperties with additionalProperties:false' => sub
{
    my $schema =
    {
        type              => 'object',
        patternProperties =>
        {
            '^x-' => { type => 'number' },
        },
        additionalProperties => JSON::false,
    };

    my $jsv = JSON::Schema::Validate->new( $schema );

    my $instance =
    {
        'x-1'   => 1,
        'x-foo' => 2,
        other   => 3,
    };

    my $pruned = $jsv->prune_instance( $instance );

    is_deeply(
        $pruned,
        {
            'x-1'   => 1,
            'x-foo' => 2,
        },
        'only properties matching patternProperties are kept'
    );
};

# allOf merging object constraints, including additionalProperties
subtest 'allOf merging properties and additionalProperties' => sub
{
    my $schema =
    {
        allOf =>
        [
            {
                type       => 'object',
                properties =>
                {
                    a => { type => 'integer' },
                },
                additionalProperties => JSON::true,
            },
            {
                type       => 'object',
                properties =>
                {
                    b => { type => 'integer' },
                },
                additionalProperties => JSON::false,
            },
        ],
    };

    my $jsv = JSON::Schema::Validate->new( $schema );

    my $instance =
    {
        a => 1,
        b => 2,
        c => 3,
    };

    my $pruned = $jsv->prune_instance( $instance );

    is_deeply(
        $pruned,
        {
            a => 1,
            b => 2,
        },
        'allOf merges properties and resolves additionalProperties:false'
    );
};

# Arrays: prefixItems + items, pruning nested objects
subtest 'array pruning with prefixItems and items' => sub
{
    my $schema =
    {
        type        => 'array',
        prefixItems =>
        [
            {
                type       => 'object',
                properties =>
                {
                    x => { type => 'integer' },
                },
                additionalProperties => JSON::false,
            },
        ],
        items =>
        {
            type       => 'object',
            properties =>
            {
                'y' => { type => 'integer' },
            },
            additionalProperties => JSON::false,
        },
    };

    my $jsv = JSON::Schema::Validate->new( $schema );

    my $instance =
    [
        { 'x' => 1, extra => 1 },
        { 'y' => 2, extra => 2 },
        3,
    ];

    my $pruned = $jsv->prune_instance( $instance );

    is_deeply(
        $pruned,
        [
            { 'x' => 1 },
            { 'y' => 2 },
            3,
        ],
        'nested objects in array items are pruned; scalar item left as-is'
    );
};

# validate() with prune_unknown => 1 uses pruned view but does not mutate caller
subtest 'validate with prune_unknown option' => sub
{
    my $schema =
    {
        type       => 'object',
        properties =>
        {
            foo => { type => 'integer' },
        },
        additionalProperties => JSON::false,
    };

    my $jsv = JSON::Schema::Validate->new(
        $schema,
        prune_unknown => 1,
    );

    my $instance =
    {
        foo => 123,
        bar => 'should be pruned for validation',
    };

    my $copy =
    {
        foo => 123,
        bar => 'should be pruned for validation',
    };

    my $ok = $jsv->validate( $instance );

    ok( $ok, 'validate succeeds when unknown property is pruned internally' );

    is_deeply(
        $instance,
        $copy,
        'validate() does not mutate caller instance even with prune_unknown'
    );
};

# scalar / non-ref instances are passed through unchanged
subtest 'prune_instance on scalar and non-structured values' => sub
{
    my $schema =
    {
        type => 'integer',
    };

    my $jsv = JSON::Schema::Validate->new( $schema );

    my $scalar = 42;
    my $pruned = $jsv->prune_instance( $scalar );

    is( $pruned, 42, 'scalar instance is returned as-is' );
};

done_testing();

__END__
