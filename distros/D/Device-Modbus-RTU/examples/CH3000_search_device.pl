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

foreach my $addr (1, 2, 3, 4, 5, 247) {

    say "Modbus unit: $addr";
    
    my $req = $client->read_holding_registers(
        unit     => $addr,
        address  => 46,
        quantity => 3,
    );

    $client->send_request($req);

    my $resp;
    eval {
        $resp = $client->receive_response;
    };
    next if $@;

    say "<-" . Dumper $resp;
}
