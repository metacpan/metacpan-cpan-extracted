#! /usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
    use_ok 'Device::Modbus::RTU::ADU';
}

{
    my $adu = Device::Modbus::RTU::ADU->new(
        unit => 'a',
        crc  => 'b'
    );
    isa_ok $adu, 'Device::Modbus::ADU';
    is $adu->unit, 'a',
        'Accessor for unit works';
    is $adu->crc, 'b',
        'Accessor for crc works';

    $adu->unit(3);
    $adu->crc(4);
    is $adu->unit, 3,
        'Mutator for unit works';
    is $adu->crc, 4,
        'Mutator for crc works';
}

{
    my $adu = Device::Modbus::RTU::ADU->new;
    eval { $adu->unit };
    like $@, qr/Unit has not/,
        'Accessor croaks if ADU does not contain a unit';

    eval { $adu->crc };
    like $@, qr/CRC has not/,
        'Accessor croaks if ADU does not contain a crc';
}

done_testing();
