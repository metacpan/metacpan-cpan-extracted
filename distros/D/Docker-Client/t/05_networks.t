#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Docker::Client;

my $client = Docker::Client->new();

eval { $client->SystemPing()->result()->is_success() };
plan skip_all => 'Docker is not running!'
  if ($@);

my $ntx = $client->NetworkCreate(
    {},
    json => {
        Name           => 'isolated',
        CheckDuplicate => 1,
        Driver         => 'bridge',
        IPAM           => {
            Config => [
                {
                    Subnet  => '172.20.0.0/16',
                    IPRange => '172.20.10.0/24',
                    Gateway => '172.20.10.12',
                }
            ]
        }
    }
);

ok( $ntx->result()->is_success(), 'NetworkCreate' );
my $network = $ntx->result()->json();

## NetworkRemove
{
    my $tx = $client->NetworkDelete( { id => $network->{Id} } );
    ok( $tx->result()->is_success(), 'NetworkRemove' );
};

done_testing();
