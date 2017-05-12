#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 5;

use Device::MindWave::Packet::Dongle::HeadsetDisconnected;
my $pkg = "Device::MindWave::Packet::Dongle::HeadsetDisconnected";

{
    my $bytes = [ 0xD2, 0x02, 0xAA, 0xBB ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new HeadsetDisconnected packet');
    is($p->code(), 0xD2, 'Packet code is correct');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Headset (AABB) disconnected',
        'Stringification is correct');
}

1;
