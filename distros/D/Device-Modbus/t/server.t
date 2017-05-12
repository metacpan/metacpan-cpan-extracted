#! /usr/bin/env perl

use lib 't/lib';
use Test::Server;
use Test::More tests => 48;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::Client';
    use_ok 'Device::Modbus::Server';
    use_ok 'Device::Modbus::ADU';
    use_ok 'TestServer';
}

{
    my $server = TestServer->new();
    ok $server->DOES('Device::Modbus::Server'),
        'The server object plays Device::Modbus::Server';

    is_deeply $server->units, {},
        'Units are saved in a hash reference which starts empty';

    eval { $server->init_server; };
    like $@, qr{Server must be initialized},
        'Initialization method must be subclassed';
}

{
    package My::Unit;
    use Test::More;
    our @ISA = ('Device::Modbus::Unit');

    sub init_unit {
        my $unit = shift;

        #                Zone            addr qty   method
        #           -------------------  ---- ---  ---------
        $unit->put('holding_registers',    2,  1,  'hello');
        $unit->get('holding_registers',    2,  1,  'good_bye');
        $unit->get('holding_registers',    3,  1,  'bad_quantity');
        $unit->put('holding_registers',    3,  6,  'multiple_regs');
        $unit->put('holding_registers',    5,  1,  'hasta_la_vista');
        $unit->get('holding_registers',    5,  1,  'hasta_la_vista');
    }

    sub hello {
        my ($unit, $server, $req, $addr, $qty, $val) = @_;
        isa_ok $unit,      'Device::Modbus::Unit';
        isa_ok $server,    'Device::Modbus::Server';
        isa_ok $req,       'Device::Modbus::Request';
        is $addr,     2,   'Address passed correctly to write routine';
        is $qty,      1,   'Quantity passed correctly to write routine';
        is $val->[0], 565, 'Value passed correctly to write routine';
    }

    sub good_bye {
        my ($unit, $server, $req, $addr, $qty) = @_;
        isa_ok $unit,      'Device::Modbus::Unit';
        isa_ok $server,    'Device::Modbus::Server';
        isa_ok $req,       'Device::Modbus::Request';
        is $addr,  2,      'Address passed correctly to read routine';
        is $qty,   1,      'Quantity passed correctly to read routine';
        return 6;
    }

    sub bad_quantity {
        my ($unit, $server, $req, $addr, $qty) = @_;
        return 6, 3;
    }

    sub multiple_regs {
        my ($unit, $server, $req, $addr, $qty, $val) = @_;
        is_deeply $val, [1,2,3,4,5,6],
            'Multiple register values received for writing';
    }

    sub hasta_la_vista {
        die 'This method always fails';
    }        
}

my $server = TestServer->new();
isa_ok $server, 'Device::Modbus::Server';

my $unit = My::Unit->new(id => 3);
$server->add_server_unit($unit);

{
    my $req = Device::Modbus::Client->write_single_register(
        address => 2,
        value   => 565
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Response';
}

{
    my $req = Device::Modbus::Client->read_holding_registers(
        address  => 2,
        quantity => 1
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Response';
    is_deeply $resp->{values}, [6],
        'Response returned correctly for read request';
}

{
    my $req = Device::Modbus::Client->write_multiple_registers(
        address  => 3,
        values   => [1,2,3,4,5,6],
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Response';
    is $resp->{code}, 0x10,
        'Response returned correctly for write multiple registers';
}

{
    my $req = Device::Modbus::Client->read_write_registers(
        read_address  => 2,
        read_quantity => 1,
        write_address => 2,
        values        => [565],
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Response';
    is_deeply $resp->{values}, [6],
        'Response returned correctly for read-write request';
}

{
    my $req = Device::Modbus::Client->read_coils(
        address  => 2,
        quantity => 4
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->{exception_code}, 1,
        'Requests for reading unsupported areas return an exception code 1';
}

{
    my $req = Device::Modbus::Client->read_holding_registers(
        address  => 3,
        quantity => 1,
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->{exception_code}, 4,
        'Exception code 4 for read routine that returns a bad qty of records';
}

{
    my $req = Device::Modbus::Client->write_single_coil(
        address  => 2,
        value    => 1,
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->{exception_code}, 1,
        'Requests for writing in unsupported areas return an exception code 1';
}

{
    my $req = Device::Modbus::Client->write_single_register(
        address  => 5,
        value    => 1,
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->{exception_code}, 4,
        'Server returns an exception code of 4 when a write routine fails';
}

{
    my $req = Device::Modbus::Client->read_holding_registers(
        address  => 5,
        quantity => 1,
    );

    my $adu = Device::Modbus::ADU->new(
        unit    => 3,
        message => $req,
    );

    my $resp = $server->modbus_server($adu);
    isa_ok $resp, 'Device::Modbus::Exception';
    is $resp->{exception_code}, 4,
        'Server returns an exception code of 4 when a read routine fails';
}

done_testing();
