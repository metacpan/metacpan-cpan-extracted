#! /usr/bin/env perl

use lib 't/lib';
use Test::More tests => 13;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::RTU::Client';
}

### Tests for generating a request

{
    my $request = Device::Modbus::RTU::Client->read_coils(
        unit     =>  3,
        address  => 19,
        quantity => 19
    );

    isa_ok $request, 'Device::Modbus::Request';

    my $adu = Device::Modbus::RTU::Client->new_adu($request);

    my $header = $adu->build_header;
    is ord($header), 3,
        'The header of the Modbus message is the unit number';

    my $footer = $adu->build_footer(chr(2),chr(7));
    is_deeply [unpack 'CC', $footer], [0x41,0x12],
        'CRC is according to the example in Modbus specification';

    my $pdu_string = unpack 'H*', $adu->binary_message;
    is $pdu_string, '0301001300138de0',
        'PDU for Read Coils function is as expected';
}

{
    my $footer = Device::Modbus::RTU::ADU->build_footer(pack('H*', '010402FFFF'), '');
    is_deeply [unpack 'CC', $footer], [0xB8, 0x80],
        'CRC is according to the example in Wikipedia';
}

{
    # Croaks if units are not defined
    my $req = Device::Modbus::RTU::Client->read_coils(
        address  => 19,
        quantity => 19
    );

    eval {
        my $adu = Device::Modbus::RTU::Client->new_adu($req);
        $adu->binary_message;
    };
    like $@, qr/unit number/,
        'Clients cannot write an ADU without unit number';
}

{
    # Croaks for unit 0
    my $req = Device::Modbus::RTU::Client->read_coils(
        unit     => 0,
        address  => 19,
        quantity => 19
    );

    eval {
        my $adu = Device::Modbus::RTU::Client->new_adu($req);
    };
    like $@, qr/Unit number/,
        'Clients cannot write an ADU for unit zero';
}

##### Parsing a response
my $client = Device::Modbus::RTU::Client->new( port => 'test' );
isa_ok $client->{port}, 'Device::SerialPort';

{
    my $response = '0103cd6b05';          # Read coils
    my $pdu = pack 'H*', "06$response";   # Unit 6
    my $crc = Device::Modbus::RTU::ADU->crc_for($pdu);
    my $adu = $pdu . $crc;
    $client->{port}->add_test_strings($adu);
    my $resp_adu = $client->receive_response;
    ok $resp_adu->success,                    'Parsed ADU without error';
    is $resp_adu->unit, 0x06,                 'Unit value retrieved is 0x06';
    is $resp_adu->function, 'Read Coils',     'Function is 0x01';
    is_deeply $resp_adu->values, [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0,0,0,0,0],
        'Values retrieved correctly';
}


done_testing();
 
