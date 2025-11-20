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

my $js = JSON::Schema::Validate->new({
    type => 'object',
    properties =>
    {
        x => 
        {
            type => 'number',
            exclusiveMinimum => 0,
            exclusiveMaximum => 1,
        },
    },
    required => [ 'x' ],
    additionalProperties => JSON::false,
});

ok(  $js->validate({ x => 0.5 }), 'between bounds' ) or diag( $js->error );
ok( !$js->validate({ x => 0   }), 'exclusiveMinimum blocks lower bound' ) or diag( $js->error );
ok( !$js->validate({ x => 1   }), 'exclusiveMaximum blocks upper bound' ) or diag( $js->error );

done_testing;

__END__
