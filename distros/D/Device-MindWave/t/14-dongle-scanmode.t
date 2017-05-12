#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 5;

use Device::MindWave::Packet::Dongle::ScanMode;
my $pkg = "Device::MindWave::Packet::Dongle::ScanMode";

{
    my $bytes = [ 0xD4, 0x01, 0x01 ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new ScanMode packet');
    is($p->code(), 0xD5, 'Packet code is correct');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Scanning',
        'Stringification is correct');
}

1;
