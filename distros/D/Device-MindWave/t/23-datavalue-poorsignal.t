#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 6;

use Device::MindWave::Packet::ThinkGear::DataValue::PoorSignal;
my $pkg = "Device::MindWave::Packet::ThinkGear::DataValue::PoorSignal";

{
    my $bytes = [ 0x02, 0x2F ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new PoorSignal data value');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Poor signal (47/200)',
        'Stringification is correct');
    is_deeply($p->as_hashref(), { PoorSignal => 47 },
        'Hashref output is correct');

    $bytes = [ 0x02, 0xC8 ];
    $p = $pkg->new($bytes, 0);
    is($p->as_string, 'Poor signal (200/200) (no signal found)',
        'Stringification is correct when no signal has been found');
}

1;
