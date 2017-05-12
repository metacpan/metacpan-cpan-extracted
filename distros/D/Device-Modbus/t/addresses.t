#!/usr/env perl

use Test::More tests => 11;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Unit::Route';
}

{
    my $addr = Device::Modbus::Unit::Route->new(
        address    => 22,
        zone       => 'holding_registers',
        quantity   => 1,
        read_write => 'read',
        routine    => sub {'hello'}
    );

    isa_ok $addr, 'Device::Modbus::Unit::Route';
}
    
{
    eval {
        my $addr = Device::Modbus::Unit::Route->new(
            address    => 22,
            zone       => 'input_registers',
            quantity   => 1,
            read_write => 'write',
            routine    => sub {'hello'}
        );
    };
    like $@, qr/is read-only/,
        'Cannot declare a write route for read-only input registers';
}

{
    eval {
        my $addr = Device::Modbus::Unit::Route->new(
            address    => 22,
            zone       => 'discrete_inputs',
            quantity   => 1,
            read_write => 'write',
            routine    => sub {'hello'}
        );
    };
    like $@, qr/is read-only/,
        'Cannot declare a write route for read-only discrete inputs';
}
{
    eval {
        my $addr = Device::Modbus::Unit::Route->new(
            # address    => 51,
            zone       => 'holding_registers',
            quantity   => 1,
            read_write => 'write',
            routine    => sub {'hello'}
        );
    };
    like $@, qr/Missing required arguments: address/,
        'Cannot declare a route without an address';
}
{
    eval {
        my $addr = Device::Modbus::Unit::Route->new(
            address    => 51,
            # zone       => 'holding_registers',
            quantity   => 1,
            read_write => 'write',
            routine    => sub {'hello'}
        );
    };
    like $@, qr/Missing required arguments: zone/,
        'Cannot declare a route without a zone';
}
{
    eval {
        my $addr = Device::Modbus::Unit::Route->new(
            address    => 51,
            zone       => 'holding_registers',
            # quantity   => 1,
            read_write => 'write',
            routine    => sub {'hello'}
        );
    };
    like $@, qr/Missing required arguments: quantity/,
        'Cannot declare an address without a quantity';
}
{
    eval {
        my $addr = Device::Modbus::Unit::Route->new(
            address    => 51,
            zone       => 'holding_registers',
            quantity   => 1,
            #read_write => 'write',
            routine    => sub {'hello'}
        );
    };
    like $@, qr/Missing required arguments: read_write/,
        'Cannot declare an address without read_write';
}
{
    eval {
        my $addr = Device::Modbus::Unit::Route->new(
            address    => 51,
            zone       => 'holding_registers',
            quantity   => 1,
            read_write => 'write',
            #routine    => sub {'hello'}
        );
    };
    like $@, qr/Missing required arguments: routine/,
        'Cannot declare an address without routine';
}
{
    eval {
        my $addr = Device::Modbus::Unit::Route->new(
            address    => 51,
            zone       => 'holding_registers',
            quantity   => 1,
            read_write => 'Write',
            routine    => sub {'hello'}
        );
    };
    like $@, qr/must be either 'read' or 'write'/,
        "read_write must be either 'read' or 'write'";
}
{
    eval {
        my $addr = Device::Modbus::Unit::Route->new(
            address    => 51,
            zone       => 'holding_registers',
            quantity   => 1,
            read_write => 'write',
            routine    => 'hello'
        );
    };
    like $@, qr/must be a code reference/,
        'The routine of an address must be a code reference';
}


done_testing();
