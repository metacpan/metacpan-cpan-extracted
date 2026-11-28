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

for my $compile ( 0, 1 )
{
    subtest "compile=$compile" => sub
    {
        # A decoded scalar can occupy the same instance path as its enclosing string.
        my $js = JSON::Schema::Validate->new(
            { type => 'string', contentSchema => { '$ref' => '#' } },
            compile => $compile, content_assert => 1 );
        ok( !$js->validate('1'), 'decoded number must not be mistaken for the active string' );
        is( (@{$js->errors} ? $js->errors->[0]->keyword : undef), 'type', 'decoded number is rejected by the referenced type' );
        is( (@{$js->errors} ? $js->errors->[0]->path : undef), '#', 'decoded content retains its enclosing instance path' );
        ok( !$js->validate('"1"'), 'nested decoded string is evaluated until the numeric leaf' );
        ok( !$js->validate('"true"'), 'nested decoded string is evaluated until the boolean leaf' );

        $js = JSON::Schema::Validate->new(
            { anyOf => [{ type => 'integer' }, { type => 'string', contentSchema => { '$ref' => '#' } }] },
            compile => $compile, content_assert => 1 );
        ok( $js->validate('"1"'), 'recursive content with a valid leaf is accepted' );
        is( scalar( @{$js->errors} ), 0, 'failed alternatives do not leak errors' );
        ok( !$js->validate('"false"'), 'recursive content with an invalid leaf is rejected' );
        ok( $js->validate(2), 'a later validation remains independent' );
        is( scalar( @{$js->errors} ), 0, 'a later successful validation clears earlier errors' );

        my $schema =
        {
            properties => { a => { type => 'integer' } },
            patternProperties => { '^a$' => { minimum => 2 } },
            unevaluatedProperties => JSON::false,
        };
        $js = JSON::Schema::Validate->new( $schema, compile => $compile );
        ok( !$js->validate({ a => 1 }), 'explicit property must also satisfy its matching pattern' );
        is( (@{$js->errors} ? $js->errors->[0]->keyword : undef), 'minimum', 'matching pattern enforces its numeric constraint' );
        ok( $js->validate({ a => 2 }), 'property satisfying both schemas is evaluated' );
        ok( !$js->validate({ a => 2, b => 1 }), 'unknown property still fails' );

        $js = JSON::Schema::Validate->new(
            { properties => { a => JSON::true }, patternProperties => { '^a$' => JSON::false } },
            compile => $compile );
        ok( !$js->validate({ a => 1 }), 'a false matching pattern cannot be bypassed by a true property schema' );

        $schema =
        {
            type => 'object',
            properties =>
            {
                nested =>
                {
                    properties => { z => JSON::false },
                    patternProperties => { '^a' => JSON::false, 'a$' => JSON::false },
                    additionalProperties => JSON::false,
                },
            },
        };
        $js = JSON::Schema::Validate->new( $schema, compile => $compile );
        ok( !$js->validate({ nested => { a => 1, z => 2 } }), 'multiple failing patterns and a later property are rejected' );
        is_deeply( [sort map{ $_->path } @{$js->errors}], ['#/nested/a', '#/nested/a', '#/nested/z'], 'every error retains its correct nested instance path' );
        is_deeply( [sort map{ $_->keyword } @{$js->errors}], ['false', 'false', 'false'], 'failed pattern is not reported as an additional property' );
        ok( !$js->validate({ nested => { a => 1, z => 2 } }, max_errors => 1), 'error limit still rejects the instance' );
        is( scalar( @{$js->errors} ), 1, 'error limit is respected for pattern failures' );
        is( (@{$js->errors} ? $js->errors->[0]->path : undef), '#/nested/a', 'early return retains the failing property path' );
        ok( $js->validate({ nested => {} }), 'a subsequent valid instance is accepted' );
    };
}

done_testing;

__END__
