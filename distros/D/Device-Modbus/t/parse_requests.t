#! /usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use Test::More tests => 59;

BEGIN {
    use_ok('TestServer');
    use_ok('Device::Modbus::ADU');
};

my @messages = (
    '0100130013',                        # Read coils
    '0200C40016',                        # Read discrete inputs
    '03006B0003',                        # Read holding registers
    '0400080001',                        # Read input registers
    '0500acff00',                        # Write single coil
    '0500ac0000',                        # Write single coil -- zero value    
    '0600010003',                        # Write single register
    '0f0013000a02cd01',                  # Write multiple coils
    '0f0013000801cd',                    # Write multiple coils -- 1 byte
    '100001000204000A0102',              # Write multiple registers
    '1700030006000E00030600FF00FF00FF',  # Read/Write multiple registers
);

my $server = TestServer->new(
    map { pack 'H*', $_ } @messages
);

# Read coils
{
    $server->set_index(0);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    isa_ok $req, 'Device::Modbus::Request';
    is $req->{code}, 0x01,
        'Read coils request has correct code number';
    is $req->{address}, 0x13,
        'Address is correct';
    is $req->{quantity}, 0x13,
        'The quantity of coils to read is correct';
}

# Read discrete inputs
{
    $server->set_index(1);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    isa_ok $req, 'Device::Modbus::Request';
    is $req->{code}, 0x02,
        'Read discrete inputs has correct code number';
    is $req->{address}, 0xC4,
        'Address is correct';
    is $req->{quantity}, 0x16,
        'The quantity of discrete inputs to read is correct';
}

# Read holding registers
{
    $server->set_index(2);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    isa_ok $req, 'Device::Modbus::Request';
    is $req->{code}, 0x03,
        'Read holding registers request has correct code number';
    is $req->{address}, 0x6B,
        'Address is correct';
    is $req->{quantity}, 0x03,
        'The quantity of holding registers to read is correct';
}

# Read input registers
{
    $server->set_index(3);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    is $req->{code}, 0x04,
        'Read input registers request has correct code number';
    is $req->{address}, 0x08,
        'Address is correct';
    is $req->{quantity}, 0x01,
        'The quantity of input registers to read is correct';
}

# Write Single Coil
{
    $server->set_index(4);
    my $read = $server->read_port;
    my $adu = $server->receive_request;
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    is $req->{code}, 0x05,
        'Write Single Coil request has correct code number';
    is $req->{address}, 0xAC,
        'Address is correct';
    is $req->{value}, 1,
        'The value to write is correct';
}

# Write Single Coil
{
    $server->set_index(5);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    is $req->{code}, 0x05,
        'Write Single Coil request has correct code number';
    is $req->{address}, 0xAC,
        'Address is correct';
    is $req->{value}, 0,
        'The value to write is correct';
}

# Write Single Register
{
    $server->set_index(6);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    is $req->{code}, 0x06,
        'Write Single Register request has correct code number';
    is $req->{address}, 0x01,
        'Address is correct';
    is $req->{value}, 0x03,
        'The value to write is correct';
}

# Write Multiple Coils
{
    $server->set_index(7);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    is $req->{code}, 0x0F,
        'Write Multiple Coils request has correct code number';
    is $req->{address}, 0x0013,
        'Address is correct';
    is $req->{quantity}, 0x000A,
        'Quantity of coils to write is correct';
    is $req->{bytes}, 2,
        'Quantity of bytes to read is correct';
    is_deeply $req->{values}, [1,0,1,1,0,0,1,1,1,0,0,0,0,0,0,0],
        'The values to write are correct';
}

# Write Multiple Coils
{
    $server->set_index(8);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    is $req->{code}, 0x0F,
        'Write Multple Coils request has correct code number';
    is $req->{address}, 0x0013,
        'Address is correct';
    is $req->{quantity}, 0x0008,
        'Quantity of coils to write is correct';
    is $req->{bytes}, 1,
        'Quantity of bytes to read is correct';
    is_deeply $req->{values}, [1,0,1,1,0,0,1,1],
        'The values to write are correct';
}

# Write Multiple Registers
{
    $server->set_index(9);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    is $req->{code}, 0x10,
        'Write Single Register request has correct code number';
    is $req->{address}, 0x0001,
        'Address is correct';
    is $req->{quantity}, 0x0002,
        'Quantity of registers to write is correct';
    is $req->{bytes}, 4,
        'Quantity of bytes to read from the port is correct';
    is_deeply $req->{values}, [0x0A, 0x0102],
        'The values to write are correct';
}

# Read-Write Multiple Registers
{
    $server->set_index(10);
    my $read = $server->read_port;
    my $adu = $server->receive_request;    
    isa_ok $adu, 'Device::Modbus::ADU';
    my $req = $adu->message;

    is $req->{code}, 0x17,
        'Read Write Multiple Registers request has correct code number';
    is $req->{read_address}, 0x0003,
        'Read address is correct';
    is $req->{read_quantity}, 0x0006,
        'Quantity of registers to read is correct';
    is $req->{write_address}, 0x000E,
        'Write address is correct';
    is $req->{write_quantity}, 0x0003,
        'Quantity of registers to write is correct';
    is $req->{bytes}, 6,
        'Quantity of bytes to read from the port is correct';
    is_deeply $req->{values}, [0x00FF, 0x00FF, 0x00FF],
        'The values to write are correct';
}

done_testing();
