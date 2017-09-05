#!/usr/bin/env perl
use 5.010;
use warnings;
use strict;

use blib;
use Lab::VXI11;

my $client = Lab::VXI11->new('132.199.98.2', DEVICE_CORE, DEVICE_CORE_VERSION, "tcp");

if (not defined $client) {
    die "cannot create client.";
}

my @args = $client->create_link(0, 0, 0, "inst0");

say "create_link_args: @args";
my $lid = $args[1];
say "lid: $lid";

my $timeout = 1000;

@args = $client->device_clear($lid, 0, $timeout, $timeout);
say "device_clear args: @args";
                              
@args = $client->device_write($lid, $timeout, 0, 0, "*IDN?\n");
say "device_write args: @args";
my $request_size = 100;

@args = $client->device_read($lid, $request_size, $timeout, 0, 0, 0);
say "device_read args: @args";
