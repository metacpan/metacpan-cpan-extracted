#! /usr/bin/env perl

use lib 't/lib';
use Test::Server;
use Test::More tests => 56;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::ADU';
    use_ok 'Test::Unit';
    use_ok 'TestServer';
}

my @messages = (
    '0100130000',                        # Read coils -- qty 0
    '01001307D1',                        # Read coils -- qty > 7D0
    '0100990013',                        # Read coils -- addr not supported
    
    '0200C40000',                        # Read discrete inputs -- qty 0
    '0200C407D1',                        # Read discrete inputs -- qty > 7d0
    '0200990013',                        # Read coils -- addr not supported

    '03006B0000',                        # Read holding registers -- qty 0
    '03006B007E',                        # Read holding registers -- qty > 7d
    '03006C0003',                        # Read holding registers -- addr not supported
    
    '0400080000',                        # Read input registers -- qty 0
    '040008007E',                        # Read input registers -- qty > 7d
    '0400090001',                        # Read input registers -- addr not supported

    '0500AC4657',                        # Write single coil -- bad value
    '0500ADFF00',                        # Write single coil -- addr not supported

    '0F0008000000',                      # Write multiple coils -- qty 0
    '0F000807B1F7' . (31)x247,           # Write multiple coils -- qty > 7B0
    '0F00080003042324',                  # Write multiple coils -- qty != bytes
    '0F000900010101',                    # Write multiple coils -- addr not supported

    '100001000000',                      # Write multiple regs -- qty 0
    '100001007CF8' . ('A010')x124,       # Write multiple regs -- qty > 7B
    '100001000206000A01020101',          # Write multiple regs -- qty != bytes

    '1700030000000E00030600FF00FF00FF',  # Read-Write -- qty to read 0
    '170003007E000E00030600FF00FF00FF',  # Read-Write -- qty to read > 7d
    '1700030003000E000000',              # Read-Write -- qty to write 0
    '1700030003000E0080FF' . (23)x256,   # Read-Write -- qty to write > 79

    '1800030003',                        # Non-existent, exception code 1
);

my @explains = (
    [3, 'Read coils -- qty 0'             ],
    [3, 'Read coils -- qty > 7D0'         ],
    [2, 'Read coils -- addr not supported'],
    
    [3, 'Read discrete inputs -- qty 0'    ],
    [3, 'Read discrete inputs -- qty > 7d0'],
    [2, 'Read coils -- addr not supported' ],

    [3, 'Read holding registers -- qty 0'             ],
    [3, 'Read holding registers -- qty > 7d'          ],
    [2, 'Read holding registers -- addr not supported'],
    
    [3, 'Read input registers -- qty 0'             ],
    [3, 'Read input registers -- qty > 7d'          ],
    [2, 'Read input registers -- addr not supported'],

    [3, 'Write single coil -- bad value'         ],
    [2, 'Write single coil -- addr not supported'],

    [3, 'Write multiple coils -- qty 0'              ],
    [3, 'Write multiple coils -- qty > 7B0'          ],
    [3, 'Write multiple coils -- bty != bytes'       ],
    [2, 'Write multiple coils -- addr not supported' ],

    [3, 'Write multiple regs -- qty 0'       ],
    [3, 'Write multiple regs -- qty > 7B'    ],
    [3, 'Write multiple regs -- qty != bytes'],

    [3, 'Read-Write -- qty to read 0'     ],
    [3, 'Read-Write -- qty to read > 7D'  ],
    [3, 'Read-Write -- qty to write 0'    ],
    [3, 'Read-Write -- qty to write > 79' ],

    [1, 'Non-supported function'],
);

my $server = TestServer->new(
    map { pack 'H*', $_ } @messages
);
isa_ok $server, 'Device::Modbus::Server';

{
    package My::Unit;
    use Test::More;
    our @ISA = ('Device::Modbus::Unit');

    sub init_unit {
        my $unit = shift;

        #                Zone            addr qty   method
        #           -------------------  ---- ---  ---------
        $unit->get('discrete_coils',      13,  1,  'hasta_la_vista');
        $unit->get('discrete_inputs',   0xC4,  1,  'hasta_la_vista');
        $unit->get('holding_registers',    2,  1,  'hasta_la_vista');
        $unit->get('input_registers',      8,  1,  'hasta_la_vista');
        $unit->put('discrete_coils',    0xAC,  1,  'hasta_la_vista');
        $unit->put('holding_registers',    8,  1,  'hasta_la_vista');
    }

    sub hasta_la_vista {
        diag "A request has been executed";
        die 'This method always fails';
    }        
}


my $unit = My::Unit->new(id => 3);
$server->add_server_unit($unit);

for my $i (0..$#messages) {
    $server->set_index($i);
    my $read = $server->read_port;
    my ($exc_code, $message) = @{$explains[$i]};

    my $adu;
    my $res;
    $adu = $server->receive_request;
    $adu->unit(3);

    if ($adu->code > 0x80) {
        # Request is invalid
        isa_ok $adu->message, 'Device::Modbus::Exception';
        is $adu->message->{exception_code}, $exc_code,
            "Code $exc_code for $message";
    }
    else {
        # Request is valid, but didn't match
        my $res = $server->modbus_server($adu);
        isa_ok $res, 'Device::Modbus::Exception';
        is $res->{exception_code}, $exc_code,
            "Code 2 for $message";
    }
}

done_testing();
