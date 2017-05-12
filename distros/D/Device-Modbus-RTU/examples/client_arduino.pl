#! /usr/bin/env perl

use Device::Modbus::RTU::Client;
use Data::Dumper;
use strict;
use warnings;
use v5.10;

my $client = Device::Modbus::RTU::Client->new(
    port     => '/dev/ttyACM0',
    baudrate => 9600,
    parity   => 'none',
    stopbits => 1,
    timeout  => 10
);

# Arduino is reset when the serial port opens. Wait for it to respond.
sleep 3;

my $req = $client->read_holding_registers(
    unit     => 3,
    address  => 0,
    quantity => 3,
);

say "->" . Dumper $req;

$client->send_request($req);
my $resp = $client->receive_response;
say "<-" . Dumper $resp;
