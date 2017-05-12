#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 42;
BEGIN { use_ok('Device::Modbus::Request') };

# Read Coils request
{
    my $request = Device::Modbus::Request->new(
        function => 'Read Coils',
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
    my $request = Device::Modbus::Request->new(
        function => 'Read Discrete Inputs',
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
    my $request = Device::Modbus::Request->new(
        function => 'Read Holding Registers',
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
    my $request = Device::Modbus::Request->new(
        function => 'Read Input Registers',
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
    my $request = Device::Modbus::Request->new(
        function => 'Write Single Coil',
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

# Write Single Coil
{
    my $request = Device::Modbus::Request->new(
        function => 'Write Single Coil',
        address  => 172,
        value    => 'A'
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x05,
        'Function code 0x05 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0500acff00',
        'PDU for Write Single Coil with arbitrary true value is correct';
}

# Write Single Coil
{
    my $request = Device::Modbus::Request->new(
        function => 'Write Single Coil',
        address  => 172,
        value    => 0
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x05,
        'Function code 0x05 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0500ac0000',
        'PDU for Write Single Coil with false value is correct';
}

# Write Single Coil
{
    my $request = Device::Modbus::Request->new(
        function => 'Write Single Coil',
        address  => 172,
        value    => undef
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x05,
        'Function code 0x05 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0500ac0000',
        'PDU for Write Single Coil with undef (false) value is correct';
}

# Write Single Coil
{
    my $request = Device::Modbus::Request->new(
        function => 'Write Single Coil',
        address  => 172,
        value    => ''
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{code}, 0x05,
        'Function code 0x05 returned correctly';

    my $pdu = $request->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0500ac0000',
        'PDU for Write Single Coil with empty string (false) value is correct';
}

# Write Single Register
{
    my $request = Device::Modbus::Request->new(
        function => 'Write Single Register',
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
    my $request = Device::Modbus::Request->new(
        function => 'Write Multiple Coils',
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
    my $request = Device::Modbus::Request->new(
        function => 'Write Multiple Registers',
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
    my $request = Device::Modbus::Request->new(
        function      => 'Read/Write Multiple Registers',
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

# Read Coils request
{
    my $request = Device::Modbus::Request->new(
        code     => 0x01,
        address  => 19,
        quantity => 19
    );

    isa_ok $request, 'Device::Modbus::Request';
    is $request->{function}, 'Read Coils',
        'Function was identified from code';

}

done_testing();
