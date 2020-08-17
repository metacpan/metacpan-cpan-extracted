#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use constant IMAGE_NAME => 'ubuntu:latest';

use Docker::Client;

my $client = Docker::Client->new();

eval { $client->SystemPing()->result()->is_success() };
plan skip_all => 'Docker is not running!'
  if ($@);

## ImageGet
{
    my $itx = $client->ImageGet( { name => IMAGE_NAME } );
    ok( $itx->result()->is_success(), 'ImageGet' );
};

## ImageInspect
{
    my $tx = $client->ImageInspect( { name => IMAGE_NAME } );
    ok( $tx->result()->is_success(), 'ImageInspect' );
};

## ImageHistory
{
    my $tx = $client->ImageHistory( { name => IMAGE_NAME } );
    ok( $tx->result()->is_success(), 'ImageHistory' );
};

done_testing();
