#! /usr/bin/env perl

use Device::Modbus::RTU::Server;
use strict;
use warnings;
use v5.10;

# This simple server can be tested with an Arduino with the
# program 'arduino_client.ino' in the examples directory


{
    package My::Unit;
    our @ISA = ('Device::Modbus::Unit');

    sub init_unit {
        my $unit = shift;

        #                Zone            addr qty   method
        #           -------------------  ---- ---  ---------
        $unit->get('holding_registers',  '*',  1,  'get_addr');
    }

    sub get_addr {
        my ($unit, $server, $req, $addr, $qty) = @_;
        $server->log(1, "Executed server routine for address $addr");
        $addr = 0 if $addr >= 5;
        return $addr + 1;
    }
}


my $server = Device::Modbus::RTU::Server->new(
    port      =>  '/dev/ttyACM0',
    baudrate  => 9600,
    parity    => 'none',
    log_level => 1
);

my $unit = My::Unit->new(id => 3);
$server->add_server_unit($unit);

$server->start;
