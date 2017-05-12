#! /usr/bin/env perl

use Device::Modbus;
use Device::Modbus::RTU::Client;
use Data::Dumper;
use strict;
use warnings;
use v5.10;

my $client = Device::Modbus::RTU::Client->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'none',
);

my $req = $client->write_single_register(
    unit     => 3,
    address  => 1,
    value    => 200
);

say "->" . Dumper $req;

$client->send_request($req);
my $resp = $client->receive_response;
say "<-" . Dumper $resp;
