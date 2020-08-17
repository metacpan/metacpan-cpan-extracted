#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Docker::Client;

my $client = Docker::Client->new();

eval { $client->SystemPing()->result()->is_success() };
plan skip_all => 'Docker is not running!'
  if ($@);

## SystemVersion
{
    my $tx = $client->SystemVersion();
    ok( $tx->result()->is_success(), 'SystemVersion' );
};

## SystemInfo
{
    my $tx = $client->SystemInfo();
    ok( $tx->result()->is_success(), 'SystemInfo' );
};

## SystemAuth
{
    my $tx = $client->SystemAuth(
        {},
        json => {
            username => 'abcd',
            password => 'efgh',
            email    => 'user@6161742.com',
        }
    );

    ok( !$tx->result()->is_success(), 'SystemAuth' );
}

done_testing();
