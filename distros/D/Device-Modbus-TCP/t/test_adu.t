#! /usr/bin/env perl

use Device::Modbus::Request;
use Test::More tests => 15;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::TCP::ADU';
}

# Test simple accessors
{
    my $adu = Device::Modbus::TCP::ADU->new;
    isa_ok $adu, 'Device::Modbus::ADU';

    my @fields = qw(id length);

    # These should die
    foreach my $field (@fields) {
        eval {
            $adu->$field;
        };
        ok defined $@, "$field accessor dies with undefined value";
        like $@, qr/not been declared/,
            "Accessor die message for undefined $field is correct";
    }

    # But these should live
    foreach my $field (@fields) {
        $adu->$field('tested OK');
        is $adu->$field, 'tested OK',
            "Accessor/mutator for $field works correctly";
    }
}

{
    my $adu = Device::Modbus::TCP::ADU->new(
        id      => 3,
        unit    => 4,
        message => Device::Modbus::Request->new(
            function => 'Write Single Coil',
            address  => 24,
            value    => 1
        )
    );
    isa_ok $adu, 'Device::Modbus::ADU';

    is $adu->id,   3, 'ID set correctly by object constructor';
    is $adu->unit, 4, 'Unit set correctly by object constructor';

    is_deeply [unpack 'nnnC', $adu->build_header], [3, 0, 6, 4],
        'Header calculated correctly';

    is_deeply [unpack 'nnnCCnn', $adu->binary_message],
        [3, 0, 6, 4, 5, 24, 0xFF00 ],
        'Binary message was calculated correctly';
}

# This one uses default unit number of 0xFF
{
    my $adu = Device::Modbus::TCP::ADU->new(
        id      => 3,
        message => Device::Modbus::Request->new(
            function => 'Write Single Coil',
            address  => 24,
            value    => 1
        )
    );
    isa_ok $adu, 'Device::Modbus::ADU';
    is $adu->unit, 0xFF, 'Unit number by default is 0xFF'
}

done_testing();
