#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 5;

use Device::MindWave::Packet::ThinkGear::DataValue::Meditation;
my $pkg = "Device::MindWave::Packet::ThinkGear::DataValue::Meditation";

{
    my $bytes = [ 0x05, 0x1F ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new Meditation data value');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Meditation (31/100)',
        'Stringification is correct');
    is_deeply($p->as_hashref(), { Meditation => 31 },
        'Hashref output is correct');
}

1;
