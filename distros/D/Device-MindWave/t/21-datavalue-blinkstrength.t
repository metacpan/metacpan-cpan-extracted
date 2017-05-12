#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 5;

use Device::MindWave::Packet::ThinkGear::DataValue::BlinkStrength;
my $pkg = "Device::MindWave::Packet::ThinkGear::DataValue::BlinkStrength";

{
    my $bytes = [ 0x16, 0xFF ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new BlinkStrength data value');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Blink strength (255/255)',
        'Stringification is correct');
    is_deeply($p->as_hashref(), { BlinkStrength => 255 },
        'Hashref output is correct');
}

1;
