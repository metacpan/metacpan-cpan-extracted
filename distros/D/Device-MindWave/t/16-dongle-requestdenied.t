#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 5;

use Device::MindWave::Packet::Dongle::RequestDenied;
my $pkg = "Device::MindWave::Packet::Dongle::RequestDenied";

{
    my $bytes = [ 0xD3, 0x00 ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new RequestDenied packet');
    is($p->code(), 0xD3, 'Packet code is correct');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Request denied',
        'Stringification is correct');
}

1;
