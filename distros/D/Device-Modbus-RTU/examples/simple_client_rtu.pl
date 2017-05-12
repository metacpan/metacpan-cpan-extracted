#! /usr/bin/env perl

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

my $req = $client->read_holding_registers(
    unit     => 4,
    address  => 0,
    quantity => 2,
);

say "->" . Dumper $req;

$client->send_request($req);
my $resp = $client->receive_response;
say "<-" . Dumper $resp;
