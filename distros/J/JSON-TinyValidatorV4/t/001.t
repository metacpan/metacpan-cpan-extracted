#!/usr/bin/env perl

use Test::More tests => 7;

use warnings;
use strict;

use_ok('JSON::TinyValidatorV4');

my $tv4 = JSON::TinyValidatorV4->new;

isa_ok( $tv4, 'JSON::TinyValidatorV4' );

my $schema = {
    type       => 'object',
    properties => {
        latitude  => { type => 'number' },
        longitude => { type => 'number' }
      }
};

my $data = {
    longitude => -128.323746,
    latitude  => -24.375870,
    elevation => 23.1
};

is( $tv4->validate( $data, $schema ), 1, 'validate banUnknownProperties=0' );
is( $tv4->validate( $data, $schema, 0, 1 ), 0, 'validate banUnknownProperties=1' );

my $result = $tv4->validateResult( $data, $schema, 0, 1 );
isa_ok( $result, "HASH" );

isa_ok( $result->{error}, "HASH" );

like( $result->{error}->{message}, qr/unknown property/i, "error.message" );
