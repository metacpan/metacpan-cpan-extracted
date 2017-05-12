#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 32;
BEGIN { use_ok('Device::Modbus::Response') };

# Build a response object for a read coils request
{
    my $response = Device::Modbus::Response->new(
        function => 'Read Coils',
        values   => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0]        
    );

    isa_ok $response, 'Device::Modbus::Response';
    is $response->{function}, 'Read Coils',
        'Function name is saved in request object correctly';
    is $response->{code}, 0x01,
        'Function code 0x01 returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0103cd6b05',
        'PDU for Read Coils function is correct';
}

# Build a response object for a read coils request
{
    my $response = Device::Modbus::Response->new(
        code     => 0x01,
        values   => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0]        
    );

    isa_ok $response, 'Device::Modbus::Response';
    is $response->{function}, 'Read Coils',
        'Function name is found from code numbers';
}

# Build a response object for a read discrete inputs request
{
    my $response = Device::Modbus::Response->new(
        function => 'Read Discrete Inputs',
        values   => [0,0,1,1,0,1,0,1,  1,1,0,1,1,0,1,1,  1,0,1,0,1,1]        
    );

    isa_ok $response, 'Device::Modbus::Response';
    is $response->{function}, 'Read Discrete Inputs',
        'Function name is saved in request object correctly';
    is $response->{code}, 0x02,
        'Function code 0x02 returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0203acdb35',
        'PDU for Read Discrete Inputs function is correct';
}

# Build a response object for a read holding registers request
{
    my $response = Device::Modbus::Response->new(
        function => 'Read Holding Registers',
        values   => [0x022b, 0x0000, 0x0064]        
    );

    isa_ok $response, 'Device::Modbus::Response';
    is $response->{function}, 'Read Holding Registers',
        'Function name is saved in request object correctly';
    is $response->{code}, 0x03,
        'Function code 0x03 returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0306022b00000064',
        'PDU for Read Holding Registers function is correct';
}

# Build a response object for a read holding registers request
{
    my $response = Device::Modbus::Response->new(
        function => 'Read Input Registers',
        values   => [0x000a]        
    );

    isa_ok $response, 'Device::Modbus::Response';
    is $response->{function}, 'Read Input Registers',
        'Function name is saved in request object correctly';
    is $response->{code}, 0x04,
        'Function code 0x04 returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0402000a',
        'PDU for Read Input Registers function is correct';
}

# Write Single Coil
{
    my $response = Device::Modbus::Response->new(
        function => 'Write Single Coil',
        address  => 172,
        value    => 1
    );

    isa_ok $response, 'Device::Modbus::Response';
    is $response->{code}, 0x05,
        'Function code 0x05 returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0500acff00',
        'PDU for Write Single Coil function is correct';
}

{
    my $response = Device::Modbus::Response->new(
        function => 'Write Single Coil',
        address  => 172,
        value    => 0
    );

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0500ac0000',
        'PDU for Write Single Coil function for false value';
}

# Write Single Register
{
    my $response = Device::Modbus::Response->new(
        function => 'Write Single Register',
        address  => 1,
        value    => 0x03
    );

    isa_ok $response, 'Device::Modbus::Response';
    is $response->{code}, 0x06,
        'Function code 0x06 returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0600010003',
        'PDU for Write Single Register function is correct';
}

# Write Multiple Coils response
{
    my $response = Device::Modbus::Response->new(
        function => 'Write Multiple Coils',
        address  => 19,
        quantity => 10
    );

    isa_ok $response, 'Device::Modbus::Response';
    is $response->{code}, 0x0f,
        'Function code 0x0f returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '0f0013000a',
        'PDU for Write Multiple Coils function is correct';
}

# Write Multiple Registers response
{
    my $response = Device::Modbus::Response->new(
        function => 'Write Multiple Registers',
        address  => 1,
        quantity => 2
    );

    isa_ok $response, 'Device::Modbus::Response';
    is $response->{code}, 0x10,
        'Function code 0x10 returned correctly';

    my $pdu = $response->pdu;
    my $pdu_string = unpack('H*', $pdu);
    is $pdu_string, '1000010002',
        'PDU for Write Multiple Registers function is correct';
}



done_testing();
