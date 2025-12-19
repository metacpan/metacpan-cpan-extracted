#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON;

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

my $schema = {
    type => 'object',
    properties => 
    {
        a => { type => 'string' },
        b => { type => 'integer' },
    },
    patternProperties => 
    {
        '^x_' =>
        {
            type => 'number'
        },
    },
    dependentRequired => 
    {
        a => [ 'b' ],
    },
    dependentSchemas => 
    {
        b => { properties => { b => { minimum => 0 } } },
    },
    propertyNames =>
    {
        pattern => '^[a-z_][a-z0-9_]*$'
    },
    additionalProperties => JSON::false,
    unevaluatedProperties => JSON::false,
    required => [ 'a' ],
};

my $js = JSON::Schema::Validate->new( $schema );

ok( !$js->validate({ a => 'hi' }), 'a implies b (dependentRequired)' );

ok( $js->validate({ a => 'hi', b => 3, x_num => 1.2 }), 'patternProperties ok; b>=0' ) or diag( $js->error );

ok( !$js->validate({ a => 'hi', b => -1 }), 'dependentSchemas minimum failed' );

ok( !$js->validate({ a => 'hi', b => 1, BAD => 1 }), 'propertyNames + unevaluatedProperties=false' );

done_testing;

__END__
