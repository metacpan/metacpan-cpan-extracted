#! /usr/bin/env perl

use lib 't/lib';
use Test::More tests => 15;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::ASCII::Client';
}

### Tests for generating a request

{
    my $request = Device::Modbus::ASCII::Client->read_coils(
        unit     =>  3,
        address  => 19,
        quantity => 19
    );

    is ref($request), 'Device::Modbus::Request',
        'Client built a Modbus request object';

    my $adu = Device::Modbus::ASCII::Client->new_adu($request);

    my $header = $adu->build_header;
    is ord($header), 3,
        'The header of the Modbus message is the unit number';

    my $pdu_string = $adu->binary_message;
    is $pdu_string, ":030100130013d6\r\n",
        'PDU for Read Coils function is as expected';
}

##### Parsing a response

{
    my $client = Device::Modbus::ASCII::Client->new( port => 'test' );
    isa_ok $client->{port}, 'Device::SerialPort';

    my $response = "0103cd6b05";            # Read coils
    my $pdu = "06" . $response;             # Unit 6
    my $lrc = Device::Modbus::ASCII::ADU->lrc_for($pdu);
    # diag "LRC to add to the response: $lrc";
    my $msg = ":". $pdu . unpack('H2', pack('C', $lrc)) . "\r\n";
    # diag "Message: <$msg>";
    
    $client->{port}->add_test_strings($msg);
    
    my $resp = $client->receive_response;
    ok $resp->success,                    'Parsed ADU without error';
    is $resp->unit, 0x06,                 'Unit value retrieved is 0x06';
    is $resp->function, 'Read Coils',     'Function is 0x01';
    is_deeply $resp->values, [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0,0,0,0,0],
        'Values retrieved correctly';
    is $resp->lrc, $lrc,
        'LRC retrieved correctly';
}

{
    # This is a read holding registers response
    my $client = Device::Modbus::ASCII::Client->new( port => 'test' );

    my $pdu = ":010302028078\r\n"; # Unit 1, function 3, 2 bytes, val=2
    my $lrc = Device::Modbus::ASCII::ADU->lrc_for(pack 'H*', "0103020280");
    # diag "LRC calculated for the response: $lrc";
    # diag "LRC in hex: " . unpack 'H*', pack 'C', $lrc;
    
    $client->{port}->add_test_strings($pdu);
    
    my $resp = $client->receive_response;
    ok $resp->success,                            'Parsed ADU successfully';
    is $resp->unit, 0x01,                         'Unit is 0x01';
    is $resp->function, 'Read Holding Registers', 'Function is 0x03';
    is $resp->values->[0], 640,                   'Values retrieved correctly';
    is $resp->lrc, $lrc,                          'LRC retrieved correctly';
}

done_testing();
