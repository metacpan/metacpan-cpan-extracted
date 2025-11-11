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

my $schema = {
    type => 'array',
    prefixItems => [
        { type => 'integer' },
        { type => 'string' }
    ],
    items => 
    {
        type => 'number'
    },
    contains =>
    {
        type    => 'number',
        minimum => 10
    },
    minContains => 1,
    unevaluatedItems => JSON::false,
};

my $js = JSON::Schema::Validate->new( $schema );

ok( $js->validate([ 1, 'x', 10 ]), 'tuple ok + contains ok; rest numeric; no unevaluated' ) or diag( $js->error );

ok( !$js->validate([ 1, 'x', 'oops' ]), 'rest must be number' );

ok( !$js->validate([ 1, 'x', 5 ]), 'contains minimum not met' );

done_testing;

__END__
