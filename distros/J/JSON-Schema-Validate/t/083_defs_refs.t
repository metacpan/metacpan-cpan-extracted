#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON ();
our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

my $schema_with_definitions =
{
    '$id'     => 'https://example.com/s/defs-definitions',
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type                 => 'object',
    additionalProperties => JSON::false,
    required             => [ 'shipping_address' ],
    properties           =>
    {
        shipping_address =>
        {
            # Classic Draft 2020-12 / 2019-09 style
            '$ref' => '#/definitions/address',
        },
    },
    definitions =>
    {
        address =>
        {
            type                 => 'object',
            additionalProperties => JSON::false,
            required             => [ 'street', 'city' ],
            properties           =>
            {
                street => { type => 'string' },
                city   => { type => 'string' },
            },
        },
    },
};

my $schema_with_defs_and_alias_pointer =
{
    '$id'     => 'https://example.com/s/defs-dollar-defs',
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    type                 => 'object',
    additionalProperties => JSON::false,
    required             => [ 'billing_address' ],
    properties           =>
    {
        billing_address =>
        {
            # NOTE:
            #   This intentionally uses "#/definitions/address" even though
            #   the schema only has "$defs". The alias logic in
            #   _jsv_resolve_internal_ref should map "definitions" -> "$defs".
            '$ref' => '#/definitions/address',
        },
    },
    '$defs' =>
    {
        address =>
        {
            type                 => 'object',
            additionalProperties => JSON::false,
            required             => [ 'street', 'city', 'postcode' ],
            properties           =>
            {
                street   => { type => 'string' },
                city     => { type => 'string' },
                postcode => { type => 'string' },
            },
        },
    },
};

my $instance_ok_definitions =
{
    shipping_address =>
    {
        street => '1-2-3 Example Street',
        city   => 'Tokyo',
    },
};

my $instance_bad_definitions_missing_city =
{
    shipping_address =>
    {
        street => '1-2-3 Example Street',
        # city missing
    },
};

my $instance_ok_defs_alias =
{
    billing_address =>
    {
        street   => '4-5-6 Another Street',
        city     => 'Osaka',
        postcode => '530-0001',
    },
};

my $instance_bad_defs_alias_missing_postcode =
{
    billing_address =>
    {
        street => '4-5-6 Another Street',
        city   => 'Osaka',
        # postcode missing
    },
};

subtest 'definitions + #/definitions/address (interpreted & compiled)' => sub
{
    my $jsv = JSON::Schema::Validate->new( $schema_with_definitions );

    ok( $jsv->validate( $instance_ok_definitions ),
        'interpreted: instance with definitions passes' )
        or diag( $jsv->error );

    ok( !$jsv->validate( $instance_bad_definitions_missing_city ),
        'interpreted: missing required field under definitions fails' );

    if( my $err = $jsv->error )
    {
        my $msg = $err->message;
        like( $msg, qr/\brequired\b/i,
            'interpreted: error mentions "required" (not unresolved $ref)' );
        is( $err->keyword, 'required',
            'interpreted: keyword is "required" for missing property' );
    }

    my $jsv_compiled = JSON::Schema::Validate->new(
        $schema_with_definitions,
        compile => 1,
    );

    ok( $jsv_compiled->validate( $instance_ok_definitions ),
        'compiled: instance with definitions passes' )
        or diag( $jsv_compiled->error );

    ok( !$jsv_compiled->validate( $instance_bad_definitions_missing_city ),
        'compiled: missing required field under definitions fails' );

    if( my $err = $jsv_compiled->error )
    {
        my $msg = $err->message;
        like( $msg, qr/\brequired\b/i,
            'compiled: error mentions "required" (not unresolved $ref)' );
        is( $err->keyword, 'required',
            'compiled: keyword is "required" for missing property' );
    }
};

subtest '$defs + alias via #/definitions/address (interpreted & compiled)' => sub
{
    my $jsv = JSON::Schema::Validate->new( $schema_with_defs_and_alias_pointer );

    ok( $jsv->validate( $instance_ok_defs_alias ),
        'interpreted: $defs aliased from #/definitions/... passes' )
        or diag( $jsv->error );

    ok( !$jsv->validate( $instance_bad_defs_alias_missing_postcode ),
        'interpreted: missing required field under $defs alias fails' );

    if( my $err = $jsv->error )
    {
        my $msg = $err->message;
        like( $msg, qr/\brequired\b/i,
            'interpreted: error mentions "required" (not unresolved $ref)' );
        is( $err->keyword, 'required',
            'interpreted: keyword is "required" for missing property' );
    }

    my $jsv_compiled = JSON::Schema::Validate->new(
        $schema_with_defs_and_alias_pointer,
        compile => 1,
    );

    ok( $jsv_compiled->validate( $instance_ok_defs_alias ),
        'compiled: $defs aliased from #/definitions/... passes' )
        or diag( $jsv_compiled->error );

    ok( !$jsv_compiled->validate( $instance_bad_defs_alias_missing_postcode ),
        'compiled: missing required field under $defs alias fails' );

    if( my $err = $jsv_compiled->error )
    {
        my $msg = $err->message;
        like( $msg, qr/\brequired\b/i,
            'compiled: error mentions "required" (not unresolved $ref)' );
        is( $err->keyword, 'required',
            'compiled: keyword is "required" for missing property' );
    }
};

subtest 'unresolved $ref under definitions produces a $ref error' => sub
{
    my $broken_schema =
    {
        '$id'     => 'https://example.com/s/defs-broken',
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        type                 => 'object',
        additionalProperties => JSON::false,
        properties           =>
        {
            foo =>
            {
                # this points to a non-existent definition
                '$ref' => '#/definitions/no_such_thing',
            },
        },
    };

    my $jsv = JSON::Schema::Validate->new( $broken_schema );

    ok( !$jsv->validate( { foo => 123 } ),
        'validation fails when $ref points to missing definition' );

    my $err = $jsv->error;
    isa_ok( $err, 'JSON::Schema::Validate::Error',
        'error is a JSON::Schema::Validate::Error object' );

    is( $err->keyword, '$ref',
        'keyword is $ref for unresolved reference' );

    like( $err->message, qr/unresolved JSON Pointer fragment in \$ref/i,
        'message mentions unresolved $ref' );

    like( $err->schema_pointer, qr{#/properties~1foo\z},
        'schema_pointer points at the failing foo schema node (parent of $ref)' );
};

done_testing();

__END__
