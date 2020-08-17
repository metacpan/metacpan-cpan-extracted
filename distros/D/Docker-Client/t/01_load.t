#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

require_ok('Docker::Client');

# Defaults
{
    my $client = Docker::Client->new();
    isa_ok( $client, 'Docker::Client' );
    can_ok( $client, qw( endpoint version ua ) );

    isa_ok( $client->endpoint(), 'Mojo::URL' );

    isa_ok( $client->ua(), 'Mojo::UserAgent' );

    is( $client->version(), 'v1.40', 'Correct default API version' );
};

## Endpoint from string
{
    my $client = Docker::Client->new(
        {
            endpoint => 'http://domain.tld'
        }
    );

    isa_ok( $client->endpoint(), 'Mojo::URL' );
    is( $client->endpoint()->to_string(),
        'http://domain.tld', 'Correct custom URL' );
};

done_testing();
