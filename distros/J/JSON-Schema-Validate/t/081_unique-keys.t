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

subtest 'uniqueKeys extension' => sub
{
    my $schema_base =
    {
        type  => "array",
        items =>
        {
            type       => "object",
            required   => ["id", "email"],
            properties =>
            {
                id    => { type => "integer" },
                email => { type => "string", format => "email" },
                name  => { type => "string" },
            },
        },
    };

    # 1. Basic single-key uniqueness
    my $schema1 =
    {
        %$schema_base,
        uniqueKeys => [ ["id"] ]
    };

    my $js1 = JSON::Schema::Validate->new( $schema1 )
        ->unique_keys(1)
        ->register_builtin_formats;

    ok(  $js1->validate( [] ),                                 'empty array ok' );
    ok(  $js1->validate( [ { id => 1, email => 'a@x' } ] ),    'single item ok' );
    ok(  $js1->validate( [ { id => 1, email => 'a@x' }, { id => 2, email => 'b@x' } ] ),
         'different ids ok' );

    my $dup = [ { id => 5, email => 'a@x' }, { id => 5, email => 'b@x' } ];
    ok( !$js1->validate( $dup ), 'duplicate id fails' );
    my $err1 = $js1->error;
    like( $err1->message, qr/uniqueKeys violation.*key.*'id'/i, 'error mentions id' );
    is( $err1->keyword, 'uniqueKeys', 'error keyword is uniqueKeys' );
    like( $err1->path, qr{^#?/\d+(?:/.*)?$}, 'path points to second duplicate item in array' );

    # Composite keys
    my $schema2 =
    {
        %$schema_base,
        uniqueKeys => [ ["id"], ["email"] ]
    };
    my $js2 = JSON::Schema::Validate->new( $schema2 )
        ->unique_keys(1)
        ->register_builtin_formats;

    my $data_ok =
    [
        { id => 1, email => 'a@x', name => 'A' },
        { id => 2, email => 'b@x', name => 'B' },
        { id => 3, email => 'c@x', name => 'C' },  # same id, different email → ok
    ];
    ok( $js2->validate( $data_ok ), 'composite: same id different email ok' );

    # Same id → fail
    my $data_bad_id =
    [
        { id => 1, email => 'a@x' },
        { id => 1, email => 'b@x' },
    ];
    ok( !$js2->validate( $data_bad_id ), 'composite: duplicate id → fail' );
    like( $js2->error->message, qr/id/i, 'error mentions id on duplicate id' );

    my $data_bad_email =
    [
        { id => 3, email => 'dup@x' },
        { id => 4, email => 'dup@x' },  # same email → fail
    ];
    ok( !$js2->validate( $data_bad_email ), 'composite: duplicate email fails' );
    like( $js2->error->message, qr/email/i, 'error mentions email' );

    # Disabled by default
    my $js_off = JSON::Schema::Validate->new( { %$schema1 } );
    ok( $js_off->validate( $dup ), 'uniqueKeys ignored when disabled' );

    # Enabled via extensions master switch
    my $js_ext = JSON::Schema::Validate->new( { %$schema1 } )->extensions(1);
    ok( !$js_ext->validate( $dup ), 'enabled via ->extensions(1)' );

    # Non-object items → ignored gracefully
    my $js_mix = JSON::Schema::Validate->new({
        type       => "array",
        uniqueKeys => [ ["id"] ],
        items      =>
        {
            # intentionally loose here: we want to see behaviour with mixed types
        },
    })->unique_keys(1);

    ok( !$js_mix->validate( [ 1, "foo", { id => 1, email => 'x' }, { id => 1, email => 'y' } ] ),
        'non-object items ignored, duplicate object ids still cause validation to fail' );

    # For this test we *do not* require "id", so items without "id" should
    # simply be ignored by uniqueKeys.
    my $schema_missing =
    {
        type       => "array",
        items      =>
        {
            type       => "object",
            properties =>
            {
                id    => { type => "integer" },
                email => { type => "string", format => "email" },
                name  => { type => "string" },
            },
        },
        uniqueKeys => [ ["id"] ],
    };

    my $js_missing = JSON::Schema::Validate->new( $schema_missing )
        ->unique_keys(1)
        ->register_builtin_formats;
    my $data_missing =
    [
        { email => 'no-id@x' },            # no id
        { id => 10, email => 'a@x' },
        { id => 11, email => 'b@x' },
    ];
    ok( $js_missing->validate( $data_missing ), 'items missing the key field do not create false positives (no required)' );
};

subtest 'composite key' => sub
{
    my $schema_composite =
    {
        type  => "array",
        items =>
        {
            type     => "object",
            required => ["category", "code"],
            properties =>
            {
                category => { type => "string" },
                code     => { type => "string" },
            },
        },
        uniqueKeys => [ ["category", "code"] ]
    };

    my $js_comp = JSON::Schema::Validate->new( $schema_composite )->unique_keys(1);

    my $ok = [
        { category => "A", code => "1" },
        { category => "A", code => "2" },  # same category, different code → ok
        { category => "B", code => "1" },  # different category → ok
    ];
    ok( $js_comp->validate( $ok ), 'true composite: combination unique across all items' );

    my $bad = [
        { category => "A", code => "1" },
        { category => "A", code => "1" },  # exact duplicate → fail
    ];
    ok( !$js_comp->validate( $bad ), 'true composite: duplicate pair → fail' );

    # Composite behaviour with missing parts (no required)
    my $schema_composite_partial =
    {
        type  => "array",
        items =>
        {
            type       => "object",
            properties =>
            {
                category => { type => "string" },
                code     => { type => "string" },
            },
        },
        uniqueKeys => [ ["category", "code"] ],
    };

    my $js_comp_partial = JSON::Schema::Validate->new( $schema_composite_partial )->unique_keys(1);

    # Items missing one part of the composite key should not be grouped
    my $partial =
    [
        { category => "C" },               # missing code
        { category => "C", code => "1" },  # full pair
        { code => "1" },                   # missing category
    ];
    ok(
        $js_comp_partial->validate( $partial ),
        'composite: items missing part of the key are ignored for uniqueness grouping (no required)'
    );
};

subtest 'uniqueKeys on nested array property' => sub
{
    my $schema_nested =
    {
        type       => "object",
        properties =>
        {
            users =>
            {
                type       => "array",
                uniqueKeys => [ ["id"] ],
                items      =>
                {
                    type       => "object",
                    required   => ["id"],
                    properties =>
                    {
                        id    => { type => "integer" },
                        email => { type => "string", format => "email" },
                    },
                },
            },
        },
    };

    my $js_nested = JSON::Schema::Validate->new( $schema_nested )
        ->unique_keys(1)
        ->register_builtin_formats;

    my $ok =
    {
        users =>
        [
            { id => 1, email => 'a@x' },
            { id => 2, email => 'b@x' },
        ],
    };
    ok( $js_nested->validate( $ok ), 'nested: distinct ids ok' );

    my $bad =
    {
        users =>
        [
            { id => 1, email => 'a@x' },
            { id => 1, email => 'b@x' },
        ],
    };
    ok( !$js_nested->validate( $bad ), 'nested: duplicate ids fail' );
    my $err = $js_nested->error;
    like( $err->message, qr/uniqueKeys/i, 'nested: error mentions uniqueKeys' );
};

subtest 'boolean key values' => sub
{
    my $schema_bool =
    {
        type  => "array",
        items =>
        {
            type       => "object",
            required   => ["flag", "id"],
            properties =>
            {
                flag => { type => "boolean" },
                id   => { type => "integer" },
            },
        },
        uniqueKeys => [ ["flag"] ],
    };

    my $js_bool = JSON::Schema::Validate->new( $schema_bool )
        ->unique_keys(1);

    my $ok =
    [
        { flag => JSON::true,  id => 1 },
        { flag => JSON::false, id => 2 },
    ];
    ok( $js_bool->validate( $ok ), 'boolean keys: true/false distinct → ok' );

    my $bad =
    [
        { flag => JSON::true, id => 1 },
        { flag => JSON::true, id => 2 },
    ];
    ok( !$js_bool->validate( $bad ), 'boolean keys: duplicate true → fail' );
    like( $js_bool->error->message, qr/flag/i, 'boolean keys: error mentions flag' );
};

done_testing();

__END__

