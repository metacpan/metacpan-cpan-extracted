#! /usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
    use_ok 'Device::Modbus::Exception';
}

{
    eval {
        Device::Modbus::Exception->new(
            exception_code => 1
        );
    };
    like $@, qr/function name or code/,
        'Exceptions need either a function name or a code number';

    eval {
        Device::Modbus::Exception->new(
            function       => 'Non-existent',
            exception_code => 1
        );
    };
    like $@, qr/Function Non-existent is not supported/,
        'Exceptions croak for unsupported functions';
}

{
    my $exception = Device::Modbus::Exception->new(
        code           => 8,
        exception_code => 1
    );
    is $exception->{function}, 'Non-supported function',
        'Unsupported code numbers do not croak';
}

{
    eval {
        Device::Modbus::Exception->new(
            code           => 0x81,
            exception_code => 8
        );
    };
    like $@, qr/A valid exception code/,
        'Non-supported exception codes croak -- too large';
}

{
    eval {
        Device::Modbus::Exception->new(
            code           => 0x81,
            exception_code => 0
        );
    };
    like $@, qr/A valid exception code/,
        'Non-supported exception codes croak -- negative';
}

{
    eval {
        Device::Modbus::Exception->new(
            code           => 0x81,
        );
    };
    like $@, qr/A valid exception code/,
        'Missing exception codes croak';
}

{
    my $pdu = Device::Modbus::Exception->new(
        code           => 0x81,
        exception_code => 4)->pdu;

    is $pdu, pack('CC', 0x81, 0x04),
        'Exception PDU is correct';
}

done_testing();
