#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 5;

use Device::MindWave::Packet::ThinkGear::DataValue::Attention;
my $pkg = "Device::MindWave::Packet::ThinkGear::DataValue::Attention";

{
    my $bytes = [ 0x04, 0x0F ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new Attention data value');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');
    is($p->as_string(), 'Attention (15/100)',
        'Stringification is correct');
    is_deeply($p->as_hashref(), { Attention => 15 },
        'Hashref output is correct');
}

1;
