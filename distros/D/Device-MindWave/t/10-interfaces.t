#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 22;

use Device::MindWave::Packet;
use Device::MindWave::Packet::Dongle;
use Device::MindWave::Packet::ThinkGear::DataValue;

my %table = (
    'Device::MindWave::Packet'
        => [qw(new as_string as_bytes)],
    'Device::MindWave::Packet::Dongle'
        => [qw(new as_string as_bytes code)],
    'Device::MindWave::Packet::ThinkGear::DataValue'
        => [qw(new as_string as_bytes as_hashref)],
);

{
    for my $pkg (keys %table) {
        for my $method (@{$table{$pkg}}) {
            eval { $pkg->$method() };
            ok($@, 'Died on calling abstract method');
            like($@, qr/Abstract method '$method' not implemented/,
                'Got correct error message');
        }
    }
}

1;
