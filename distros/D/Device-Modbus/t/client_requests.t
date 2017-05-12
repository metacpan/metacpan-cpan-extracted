#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 28;
BEGIN { use_ok('Device::Modbus::Client') };

my $client = bless {}, 'Device::Modbus::Client';

# Read Coils request
{
    my $request = $client->read_coils(
        address  => 19,
        quantity => 19
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x01, 'Function code 0x01 works correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0100130013',
        'PDU for Read Coils function is correct';
}

# Read Discrete Inputs
{
    my $request = $client->read_discrete_inputs(
        address  => 196,
        quantity => 218-196
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x02,
        'Function code 0x02 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0200c40016',
        'PDU for Read Discrete Inputs function is correct';
}

# Read Holding Registers
{
    my $request = $client->read_holding_registers(
        address  => 107,
        quantity => 110-107
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x03,
        'Function code 0x03 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '03006b0003',
        'PDU for Read Holding Registers function is correct';
}

# Read Input Registers
{
    my $request = $client->read_input_registers(
        address  => 8,
        quantity => 1
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x04,
        'Function code 0x04 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0400080001',
        'PDU for Read Input Registers function is correct';
}

# Write Single Coil
{
    my $request = $client->write_single_coil(
        address  => 172,
        value    => 1
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x05,
        'Function code 0x05 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0500acff00',
        'PDU for Write Single Coil function is correct';
}

# Write Single Register
{
    my $request = $client->write_single_register(
        address  => 1,
        value    => 0x03
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x06,
        'Function code 0x06 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0600010003',
        'PDU for Write Single Register function is correct';
}

# Write Multiple Coils
{
    my $request = $client->write_multiple_coils(
        address  => 19,
        values   => [1,0,1,1,0,0,1,1,1,0]
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x0F,
        'Function code 0x0F returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0f0013000a02cd01',
        'PDU for Write Multiple Coils function is correct';
}

# Write Multiple Registers
{
    my $request = $client->write_multiple_registers(
        address  => 1,
        values   => [0x000A, 0x0102]
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x10,
        'Function code 0x10 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '100001000204000a0102',
        'PDU for Write Multiple Registers function is correct';
}

# Issue a Read/Write Multiple Registers request
{
    my $request = $client->read_write_registers(
        read_address  => 3,
        read_quantity => 6,
        write_address => 14,
        values        => [0x00ff, 0x00ff, 0x00ff]
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x17,
        'Function code 0x17 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '1700030006000e00030600ff00ff00ff',
        'PDU for Read Write Registers function is correct';
}


done_testing();
