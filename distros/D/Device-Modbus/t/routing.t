#!/usr/env perl

use List::Util qw(shuffle);
use Test::More tests => 137;
use strict;
use warnings;
use v5.10;

BEGIN {
    use_ok 'Device::Modbus::Unit::Route';
}

my @tests = (
    6,
    '3, 8,5',
    '1-5',
    '1,3, 5 - 7,9',
    '*',
    '33-36',
    '101, 145, 23-28, 56-60',
);

my @test_values = (
    { true => [6],           false => [1, 5, 7, 66]},
    { true => [3,5, 8],      false => [1,2,4,6,7,9, 58]},
    { true => [1,2,3,4,5],   false => [0, 6, 9, 44]},
    { true => [1,3,5,6,7,9], false => [0,2,4,8,10, 90, 19] },
    { true => [1,3,5,6,7,9], false => []  },
    { true => [33,34,35,36], false => [32,37, 63, 43]},
    {
        true  => [101,145,23,25,28,56,58,60],
        false => [100, 21,22,29,55,61,600,560],
    },
);

foreach my $index (0..$#tests) {
    my $route = $tests[$index];
    my $tvals = $test_values[$index];

    {
        my $address = Device::Modbus::Unit::Route->new(
            address    => $route,
            zone       => 'holding_registers',
            quantity   => 1,
            read_write => 'read',
            routine    => sub {'hello'}
        );

        foreach my $val (shuffle @{$tvals->{true}}) {
            ok $address->test_route($val), "Address $val matches route '$route'";
        }

        foreach my $val (shuffle @{$tvals->{false}}) {
            ok !$address->test_route($val), "Address $val does not match route '$route'";
        }
    }

    {
        my $address = Device::Modbus::Unit::Route->new(
            address    => 22,
            zone       => 'holding_registers',
            quantity   => $route,
            read_write => 'read',
            routine    => sub {'hello'}
        );

        foreach my $val (shuffle @{$tvals->{true}}) {
            ok $address->test_quantity($val), "Quantity $val matches '$route'";
        }

        foreach my $val (shuffle @{$tvals->{false}}) {
            ok !$address->test_quantity($val), "Quantity $val does not match '$route'";
        }
    }
}

{
    eval {
        my $address = Device::Modbus::Unit::Route->new(
            address    => 22,
            zone       => 'near the border',
            quantity   => 5,
            read_write => 'read',
            routine    => sub {'hello'}
        );
    };
    like $@, qr/Invalid Modbus model type/,
        "Routes die of invalid Modbus zone declarations";

    eval {
        my $address = Device::Modbus::Unit::Route->new(
            address    => 22,
            zone       => 'discrete_inputs',
            quantity   => 7,
            read_write => 'read',
            routine    => ['array', 'ref']
        );
    };
    like $@, qr/must be a code reference/,
        "Routes accept only code references";

}
        
done_testing();
