#! /usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
    use_ok 'Device::Modbus::RTU::Client';
}

# Loads the fake serial port from t/lib
my $client = Device::Modbus::RTU::Client->new( port => 'test' );
isa_ok $client->{port}, 'Device::SerialPort';

{
    my $request = Device::Modbus::RTU::Client->read_coils(
        unit     =>  3,
        address  => 19,
        quantity => 19
    );

    my $adu = Device::Modbus::RTU::Client->new_adu($request);

    $client->write_port($adu);
    is(Device::SerialPort->get_test_string, $adu->binary_message,
        'Writing to the serial port should work')   ;
    is $client->disconnect, 1,
        'Disconnecting the serial port should work';
}
{
    eval {
        my $client2 = Device::Modbus::RTU::Client->new;
    };
    like $@, qr/'port' is required/,
        'A port is required to instantiate a new RTU client';
}
{
    my $client3 = Device::Modbus::RTU::Client->new(
        port     => 'COM1',
        baudrate => 19400,
        parity   => 'odd',
        databits => 8,
        stopbits => 1,
        timeout  => 2
    );

    isa_ok $client3, 'Device::Modbus::Client';
}

done_testing();

