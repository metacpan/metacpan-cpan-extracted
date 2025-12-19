#!/usr/bin/env perl
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

my $schema =
{
    type => 'object',
    properties => 
    {
        fixed => { type => 'integer' },
    },
    patternProperties => 
    {
        '^x_' => { type => 'string' },
    },
    additionalProperties => JSON::false,
};

my $js = JSON::Schema::Validate->new( $schema );

ok(  $js->validate( { fixed => 1, x_name => 'ok' } ), 'property and patternProperty allowed' ) or diag( $js->error );
ok( !$js->validate( { fixed => 1, y_bad  => 0     } ), 'additionalProperties=false blocks unmatched "y_bad"' );

done_testing;

__END__
