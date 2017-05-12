#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 5;

use Device::MindWave::Packet::Dongle::HeadsetFound;
my $pkg = "Device::MindWave::Packet::Dongle::HeadsetFound";

{
    my $bytes = [ 0xD0, 0x02, 0xAA, 0xBB ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new HeadsetFound packet');
    is($p->code(), 0xD0, 'Packet code is correct');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Headset (AABB) found',
        'Stringification is correct');
}

1;
