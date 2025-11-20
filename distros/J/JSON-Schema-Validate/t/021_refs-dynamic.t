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
}

# Linked-list style recursion using $dynamicAnchor/$dynamicRef
my $schema = {
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    '$id'     => 'https://example.org/s/node.json',
    type      => 'object',
    required  => [ 'name' ],
    properties => {
        name =>
        {
            type => 'string',
            minLength => 1
        },
        next =>
        {
            '$dynamicRef' => '#Node'
        },
    },
    '$dynamicAnchor' => 'Node',
    additionalProperties => JSON::false,
};

my $js = JSON::Schema::Validate->new( $schema );

ok( $js->validate({ name => 'a' }), 'single node' ) or diag( $js->error );

ok( $js->validate({ name => 'a', next => { name=>'b' } }), 'two nodes' ) or diag( $js->error );

ok( !$js->validate({ name => 'a', next => { name=>'' } }), 'invalid recursive child' );

done_testing;

__END__
