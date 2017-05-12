#! /usr/bin/env perl

use Device::Modbus::RTU::Client;
use Data::Dumper;
use strict;
use warnings;
use v5.10;

my $client = Device::Modbus::RTU::Client->new(
    port     => '/dev/ttyUSB0',
    baudrate => 9600,
    parity   => 'none',
);

my $req = $client->write_single_register(
    unit     => 247,
    address  => 46,
    value    => 4,
);

say "->" . Dumper $req;

$client->send_request($req);
my $resp = $client->receive_response;
say "<-" . Dumper $resp;
