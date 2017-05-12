#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 7;

use Device::MindWave::Utils qw(checksum
                               packet_isa
                               packet_to_bytes);
use Device::MindWave::Packet::Dongle::RequestDenied;

{
    my @checksum_tests = (
        [ [ 0x00 ] => 0xFF ],
        [ [ 0x00, 0x00, 0x00 ] => 0xFF ],
        [ [ 0x01, 0x02, 0x03 ] => 0xF9 ],
    );

    for my $test (@checksum_tests) {
        my ($input, $exp_output) = @{$test};
        my $output = checksum($input);
        is($output, $exp_output,
            'Got correct output for checksum of '.
            '['.(join ' ', map { sprintf '0x%X', $_ } @{$input}).']');
    }
}

{
    ok((not packet_isa(100, 'Dongle::HeadsetFound')),
        'Number is not a packet');
    my $p = Device::MindWave::Packet::Dongle::RequestDenied->new();
    ok((not packet_isa($p, 'Dongle::HeadsetFound')),
        'Packet is not a HeadsetFound packet');
    ok((packet_isa($p, 'Dongle::RequestDenied')),
        'Packet is a RequestDenied packet');
    my $bytes = packet_to_bytes($p);
    is_deeply($bytes, [ 0xAA, 0xAA, 0x02, 0xD3, 0x00, 0x2C ],
        'Got correct packet bytes');
}


1;
