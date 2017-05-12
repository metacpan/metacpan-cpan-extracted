#! /usr/bin/perl

use Device::Modbus::Client;
use Device::Modbus::TCP::Client;
use Data::Dumper;
use strict;
use warnings;
use v5.10;

my $client = Device::Modbus::TCP::Client->new(
    host => '192.168.1.34',
);

my $req = $client->read_holding_registers(
    unit     => 3,
    address  => 2,
    quantity => 1
);

say Dumper $req;
$client->send_request($req) || die "Send error: $!";
my $response = $client->receive_response;
say Dumper $response;

$client->disconnect;
