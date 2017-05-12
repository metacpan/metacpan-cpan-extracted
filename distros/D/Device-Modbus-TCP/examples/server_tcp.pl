#! /usr/bin/env perl

use Device::Modbus::TCP::Server;
use strict;
use warnings;
use v5.10;

{
    package My::Unit;
    our @ISA = ('Device::Modbus::Unit');

    sub init_unit {
        my $unit = shift;

        #                Zone            addr qty   method
        #           -------------------  ---- ---  ---------
        $unit->get('holding_registers',    2,  1,  'get_addr_2');
    }

    sub get_addr_2 {
        my ($unit, $server, $req, $addr, $qty) = @_;
        $server->log(4,"Executed server routine for address 2, 1 register");
        return 6;
    }
}

my $server = Device::Modbus::TCP::Server->new(
    log_level => 4,
#    log_file  => 'logfile'
);

my $unit = My::Unit->new(id => 3);
$server->add_server_unit($unit);

$server->start;
