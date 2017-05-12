package Test::Unit;

use parent 'Device::Modbus::Unit';
use strict;
use warnings;

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

1;
