#! /usr/bin/env perl

use Test::More tests => 51;
use lib 't/lib';
use strict;
use warnings;

BEGIN {
    use_ok('TestClient');
    use_ok('Device::Modbus::ADU');
};

my @messages = (
    '0103cd6b05',                    # Read coils
    '0203acdb35',                    # Read discrete inputs
    '0306022b00000064',              # Read holding registers
    '0402000a',                      # Read input registers
    '0500acff00',                    # Write single coil
    '0600010003',                    # Write single register
    '0f0013000a',                    # Write multiple coils
    '1000010002',                    # Write multiple registers
    '170c00fe0acd00010003000d00ff',  # Read/Write multiple registers
    '0500ac0000',                    # Write single coil - false value
    '8503',                          # Exception code 3 for function 5
    '79',                            # Bad input
    '03000d00ff0103cd6b05',          # Bogus before a Read coils resp
    '0100cd6b05',                    # Read coils - zero bytes
    '04fc000a',                      # Read input registers > 250 bytes
    '040100',                        # Read input registers odd bytes
);

my $client = TestClient->new(
    map { pack 'H*', $_ } @messages
);


# Read coils
{
    $client->set_index(0);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 1,
        'Read coils code has been read correctly';
    is $response->{function}, 'Read Coils',
        'Function has been identified';
    is $response->{bytes}, 3,
        'The byte count was read correctly';
    is_deeply $response->{values}, [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0,0,0,0,0],
        'The transmitted values have been recuperated correclty';
}

# Read discrete inputs
{
    $client->set_index(1);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 2,
        'Read discrete inputs code has been read correctly';
    is $response->{function}, 'Read Discrete Inputs',
        'Function has been identified';
    is $response->{bytes}, 3,
        'The byte count was read correctly';
    is_deeply $response->{values}, [0,0,1,1,0,1,0,1,  1,1,0,1,1,0,1,1,  1,0,1,0,1,1,0,0],
        'The transmitted values have been recuperated correclty';
}

# Read holding registers
{
    $client->set_index(2);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 3,
        'Read holding registers code has been read correctly';
    is $response->{function}, 'Read Holding Registers',
        'Function has been identified';
    is $response->{bytes}, 6,
        'The byte count was read correctly';
    is_deeply $response->{values}, [0x022b, 0x0000, 0x0064],
        'The transmitted values have been recuperated correclty';
}

# Read input registers
{
    $client->set_index(3);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 4,
        'Read input registers code has been read correctly';
    is $response->{function}, 'Read Input Registers',
        'Function has been identified';
    is $response->{bytes}, 2,
        'The byte count was read correctly';
    is_deeply $response->{values}, [0x000a],
        'The transmitted values have been recuperated correclty';
}

# Write single coil
{
    $client->set_index(4);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 5,
        'Write single coil code has been read correctly';
    is $response->{function}, 'Write Single Coil',
        'Function has been identified';
    is $response->{address}, 172,
        'The address was read correctly';
    is_deeply $response->{value}, 1,
        'The transmitted value, 1, has been recuperated correclty';
}

# Write single coil
{
    $client->set_index(9);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 5,
        'Write single coil code has been read correctly';
    is $response->{function}, 'Write Single Coil',
        'Function has been identified';
    is $response->{address}, 172,
        'The address was read correctly';
    is_deeply $response->{value}, 0,
        'The transmitted value, zero, has been recuperated correclty';
}

# Write single register
{
    $client->set_index(5);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 6,
        'Write single register code has been read correctly';
    is $response->{function}, 'Write Single Register',
        'Function has been identified';
    is $response->{address}, 1,
        'The address was read correctly';
    is_deeply $response->{value}, 0x03,
        'The transmitted value has been recuperated correclty';
}

# Write multiple coils
{
    $client->set_index(6);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 0x0f,
        'Write multiple coils code has been read correctly';
    is $response->{function}, 'Write Multiple Coils',
        'Function has been identified';
    is $response->{address}, 19,
        'The address was read correctly';
    is_deeply $response->{quantity}, 10,
        'The quantity of written coils has been recuperated correclty';
}

# Write multiple registers
{
    $client->set_index(7);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 0x10,
        'Write multiple registers code has been read correctly';
    is $response->{function}, 'Write Multiple Registers',
        'Function has been identified';
    is $response->{address}, 1,
        'The address was read correctly';
    is_deeply $response->{quantity}, 2,
        'The quantity of written registers has been recuperated correclty';
}

# Read/write registers
{
    $client->set_index(8);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 0x17,
        'Read/Write multiple registers code has been read correctly';
    is $response->{function}, 'Read/Write Multiple Registers',
        'Function has been identified';
    is $response->{bytes}, 12,
        'The byte count was read correctly';
    is_deeply $response->{values}, [0x00fe, 0x0acd, 0x0001, 0x0003, 0x000d, 0x00ff],
        'The transmitted values have been recuperated correclty';
}

# Exception
{
    $client->set_index(10);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response = $client->parse_pdu($adu);
    is $response->{code}, 0x85,
        'Houston, we have an exception';
    is $response->{function}, 'Write Single Coil',
        'Function has been identified';
    is $response->{exception_code}, 3,
        'Exception code is correct';
}

# Bad input
{
    $client->set_index(11);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    eval {
        $client->parse_pdu($adu);
    };
    like $@, qr/Unimplemented function: <121>/,
        'Response parsing dies with bad data';
}

# Starts at the middle of a message
{
    $client->set_index(12);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    my $response;
    do {
        eval {
            $response = $client->parse_pdu($adu);
        };
        # diag $@;
    }
    while ($@ !~ /^Timeout/);
    
    is $response->{function}, 'Read Coils',
        'Function has been identified';
    is_deeply $response->{values}, [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0,0,0,0,0],
        'The transmitted values have been recuperated correclty';
    # diag explain $@;
    # diag explain $response;
}

# Bad read coils request
{
    $client->set_index(13);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    eval {
        $client->parse_pdu($adu);
    };
    like $@, qr/Invalid byte count: <0>/,
        'Response parsing dies when response makes no sense';
}

# Bad read registers request
{
    $client->set_index(14);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    eval {
        $client->parse_pdu($adu);
    };
    like $@, qr/Invalid byte count: <252>/,
        'Reading registers dies when bytes > 250';
}

{
    $client->set_index(15);
    my $read = $client->read_port;
    my $adu = Device::Modbus::ADU->new();
    eval {
        $client->parse_pdu($adu);
    };
    like $@, qr/Invalid byte count: <1>/,
        'Reading registers dies when number of bytes is odd';
}
done_testing();
