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
    '$schema' => 'https://json-schema.org/draft/2020-12/schema',
    '$id'     => 'https://example.org/schemas/root.json',
    '$defs'   =>
    {
        name =>
        {
            '$anchor' => 'Name',
            type => 'string',
            minLength => 1,
        },
    },
    type => 'object',
    properties =>
    {
        name => { '$ref' => '#Name' },      # via $anchor combined to absolute id
        age  => { '$ref' => '#/defsAge' },  # pointer
    },
    required => [ 'name', 'age' ],
    additionalProperties => JSON::false,
    defsAge =>
    {
        '$id'   => 'age.json',
        type    => 'integer',
        minimum => 0,
    },
};

my $js = JSON::Schema::Validate->new( $schema );

ok( $js->validate({ name => 'Yuri', age => 10 }), 'in-doc refs resolve' ) or diag( $js->error );
ok( !$js->validate({ name => '', age => 10 }), 'anchor minLength enforced' );
ok( !$js->validate({ name => 'Jack', age => -1 }), 'age minimum enforced' );

done_testing;

__END__
