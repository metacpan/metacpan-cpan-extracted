#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 10;

use Device::MindWave::Packet::ThinkGear::DataValue::RawWave;
my $pkg = "Device::MindWave::Packet::ThinkGear::DataValue::RawWave";

{
    my $bytes = [ 0x80, 0x02, 0xFF, 0xFF ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new RawWave data value');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Raw wave: -1',
        'Stringification is correct');
    is_deeply($p->as_hashref(), { RawWave => -1 },
        'Hashref output is correct');

    $bytes = [ 0x80, 0x02, 0x00, 0xFF ];

    $p = $pkg->new($bytes, 0);
    ok($p, 'Got new RawWave data value');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Raw wave: 255',
        'Stringification is correct');
    is_deeply($p->as_hashref(), { RawWave => 255 },
        'Hashref output is correct');
}

1;
