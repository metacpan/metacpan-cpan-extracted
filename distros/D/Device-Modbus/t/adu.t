#! /usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 23;

BEGIN {
    use_ok 'Device::Modbus::ADU';
    use_ok 'Device::Modbus::Response';
}

{
    my $adu = Device::Modbus::ADU->new(
        unit     => 3,
        message  => 'a request',
    );
    isa_ok $adu, 'Device::Modbus::ADU';
    is $adu->message, 'a request',
        'Accessor for messages works';
    is $adu->unit, 3,
        'Accessor for unit works';

    $adu->message(3);
    is $adu->message, 3,
        'Mutator for message works';
    $adu->unit(5);
    is $adu->unit, 5,
        'Mutator for unit works';    
}

{
    my $adu = Device::Modbus::ADU->new;
    eval { $adu->message };
    like $@, qr/does not contain any messages/,
        'Accessor croaks if ADU does not contain a message';
}

{
    my $response = Device::Modbus::Response->new(
        function => 'Read Coils',
        values   => [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0]        
    );
    my $adu = Device::Modbus::ADU->new;
    $adu->message($response);

    is $adu->function, 'Read Coils',
        'Function name retrieved directly from ADU';
    ok $adu->success, 'ADU is successful for a proper response';
    is_deeply $adu->values,
        [1,0,1,1,0,0,1,1,   1,1,0,1,0,1,1,0,  1,0,1,0],
        'Response values retrieved directly from ADU';
}

{
    my $response = Device::Modbus::Response->new(
        function => 'Write Single Coil',
        address  => 23,
        value    => 1        
    );
    my $adu = Device::Modbus::ADU->new;
    $adu->message($response);

    is_deeply $adu->values, [1],
        'Response value retrieved directly from ADU';
}

{
    my $response = Device::Modbus::Exception->new(
        function       => 'Read Coils',
        exception_code => 3,
    );
    my $adu = Device::Modbus::ADU->new;
    $adu->message($response);

    is $adu->function, 'Read Coils',
        'Function name retrieved directly from ADU';
    ok !$adu->success, 'ADU is not successful for exception objects';
}

{
    my $adu = Device::Modbus::ADU->new;
    ok !$adu->success, 'ADU is not successful if it has no message';
    eval {
        $adu->unit;
    };
    like $@, qr/Unit has not been declared/,
        'Unit accessor croaks if the unit number has not been declared';

    $adu->unit(1);
    is $adu->unit, 1,
        'Unit number has not been changed from a valid value';
    eval {
        $adu->unit(-1);
    };
    like $@, qr/Unit number is invalid/,
        'Unit accessor croaks if the unit number is zero';
    is $adu->unit, 1,
        'Unit number has not been changed from a valid value';

    eval {
        $adu->unit(256);
    };
    like $@, qr/Unit number is invalid/,
        'Unit accessor croaks if the unit number is > 255';
    is $adu->unit, 1,
        'Unit number has not been changed from a valid value';

    eval {
        $adu->unit(255);
    };
    ok !$@, 'Unit mutator survives for valid numbers';
    is $adu->unit, 255,
        'And the unit number is correclty saved';
}

done_testing();
