#! /usr/bin/env perl

use Test::More tests => 7;
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus';
}

{
    # MSB is to the right, so the array below is 13 and not 11.
    my @values = (1,0,1,1);
    my $flat   = Device::Modbus->flatten_bit_values(\@values);
    my @expanded = @$flat;
    is scalar(@expanded), 1,
        'I got one character back';
    is ord($expanded[0]), 13,
        'The character is indeed number thirdteen';
}

{
    # We should get two bytes here: 0x90, 0x01 
    my @values = (0,0,0,0,1,1,0,1,1);
    my $flat   = Device::Modbus->flatten_bit_values(\@values);
    my @expanded = @$flat;
    is scalar(@expanded), 2,
        'I got two characters back';
    my @numbers = map {ord($_)} @expanded;
    is $numbers[0], 0xB0,
        'First character is 0xB0';
    is $numbers[1], 1,
        'Second character is just one';
}

{
    # From the example for function 0x01 in the MODBUS application
    # protocol v1.1b
    my @flat = (0xcd, 0x6b, 0x05); 
    my @values = (
        1, 0, 1, 1, 0, 0, 1, 1,
        1, 1, 0, 1, 0, 1, 1, 0,
        1, 0, 1, 0, 0, 0, 0, 0,
    );
    is_deeply [Device::Modbus->explode_bit_values(@flat)], \@values,
        'Bits exploded correctly from a set of bytes';
}

done_testing();
