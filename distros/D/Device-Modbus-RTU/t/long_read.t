#! /usr/bin/env perl

use Test::More tests => 3;
use Device::Modbus::RTU::Client;
use Data::Dumper;
use strict;
use warnings;
use v5.10;

SKIP: {
    skip 'A physical connection is needed to run this test', 3
        unless $ENV{TEST_PORT};

    my $client = Device::Modbus::RTU::Client->new(
        port     => '/dev/ttyACM0',
        baudrate => 9600,
        parity   => 'none',
        stopbits => 1,
        timeout  => 10
    );

    sleep 3;

    my $req = $client->read_holding_registers(
        unit     => 3,
        address  => 0,
        quantity => 3,
    );

    note "->" . Dumper $req;

    $client->send_request($req);
    my $resp = $client->receive_response;
    note "<-" . Dumper $resp;
    is ref($resp), 'Device::Modbus::RTU::ADU',
        'The late response from an Arduino was read';
    is $resp->function, 'Read Holding Registers',
        'And the response is correct';
    ok $resp->success,
        'And without error';
}

done_testing();

