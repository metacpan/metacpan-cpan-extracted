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
        my $check = sub
        {
            my( $schema, $data, $expected, $label ) = @_;
            my $js = JSON::Schema::Validate->new( $schema, compile => $compile );
            is( $js->validate( $data ) ? 1 : 0, $expected, $label ) or diag( $js->error );
        };
        my $a = { properties => { a => { type => 'integer' } }, required => ['a'] };
        my $b = { properties => { b => { type => 'integer' } }, required => ['b'] };
        my $schema = {
            definitions => { a => $a },
            allOf => [{ '$ref' => '#/definitions/a' }, $b],
            unevaluatedProperties => JSON::false,
        };
        $check->( $schema, { a => 1, b => 2 }, 1, 'allOf merges referenced properties' );
        $check->( $schema, { a => 1, b => 2, c => 3 }, 0, 'allOf still rejects unknown properties' );
        $check->( $schema, { a => 'invalid', b => 2 }, 0, 'allOf still validates property types' );
        $check->( $schema, { b => 2 }, 0, 'allOf still enforces required fields' );
        $schema = { anyOf => [$a, $b], unevaluatedProperties => JSON::false };
        $check->( $schema, { a => 1, b => 2 }, 1, 'anyOf merges all successful branches' );
        $check->( $schema, { a => 1 }, 1, 'anyOf accepts one successful branch' );
        $check->( $schema, { a => 1, b => 'invalid' }, 0, 'anyOf ignores annotations from failed branches' );
        $check->( $schema, { c => 1 }, 0, 'anyOf rejects if no branch succeeds' );
        $schema = { oneOf => [$a, $b], unevaluatedProperties => JSON::false };
        $check->( $schema, { a => 1 }, 1, 'oneOf retains selected annotations' );
        $check->( $schema, { a => 1, b => 2 }, 0, 'oneOf rejects multiple successful branches' );
        $check->( $schema, { a => 1, c => 2 }, 0, 'oneOf still rejects unknown properties' );
        $schema = { properties => { a => { type => 'integer' } }, additionalProperties => JSON::true, unevaluatedProperties => JSON::false };
        $check->( $schema, { a => 1, b => 2 }, 1, 'explicit additionalProperties true contributes annotations' );
        $schema = { properties => { a => { type => 'integer' } }, unevaluatedProperties => JSON::false };
        $check->( $schema, { a => 1, b => 2 }, 0, 'absent additionalProperties contributes no annotations' );
        $schema = { properties => { a => { type => 'integer' } }, dependentSchemas => { a => $b }, unevaluatedProperties => JSON::false };
        $check->( $schema, { a => 1, b => 2 }, 1, 'dependentSchemas contributes annotations' );
        $check->( $schema, { a => 1, b => 2, c => 3 }, 0, 'dependentSchemas does not permit unknown properties' );
        $schema = { if => $a, then => $b, unevaluatedProperties => JSON::false };
        $check->( $schema, { a => 1, b => 2 }, 1, 'successful if and then contribute annotations' );
        $check->( $schema, { a => 1, b => 'invalid' }, 0, 'then still validates its properties' );
        $schema = { allOf => [{ unevaluatedProperties => JSON::true }], unevaluatedProperties => JSON::false };
        $check->( $schema, { a => 1 }, 1, 'unevaluatedProperties true annotates remaining properties' );
        $schema = { allOf => [$a], unevaluatedProperties => { type => 'string' } };
        $check->( $schema, { a => 1, b => 'ok' }, 1, 'unevaluatedProperties schema applies only to remaining properties' );
        $check->( $schema, { a => 1, b => 2 }, 0, 'unevaluatedProperties schema rejects an invalid remaining property' );
        $schema = { allOf => [{ prefixItems => [{ type => 'integer' }] }], unevaluatedItems => JSON::false };
        $check->( $schema, [1], 1, 'allOf contributes array annotations' );
        $check->( $schema, [1, 2], 0, 'allOf still rejects unknown items' );
        $schema = { contains => { type => 'integer' }, unevaluatedItems => JSON::false };
        $check->( $schema, [1, 2], 1, 'contains annotates all matching items' );
        $check->( $schema, [1, 'bad'], 0, 'contains does not annotate non-matching items' );
        $schema = { definitions => { a => $a }, oneOf => [{ '$ref' => '#/definitions/a' }, { '$ref' => '#/definitions/a' }] };
        $check->( $schema, { a => 'bad' }, 0, 'failed reference is not treated as successful when revisited' );
        $check->( $schema, { a => 1 }, 0, 'revisited successful reference counts as a second match' );
        $schema = { definitions => { a => $a }, allOf => [{ '$ref' => '#/definitions/a' }, { '$ref' => '#/definitions/a' }], unevaluatedProperties => JSON::false };
        $check->( $schema, { a => 1 }, 1, 'independent reference evaluations retain annotations' );
    };
}

done_testing;

__END__
