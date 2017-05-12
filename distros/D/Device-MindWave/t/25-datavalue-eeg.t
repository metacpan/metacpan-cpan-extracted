#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 5;

use Device::MindWave::Packet::ThinkGear::DataValue::EEG;
my $pkg = "Device::MindWave::Packet::ThinkGear::DataValue::EEG";

{
    my $bytes = [ 0x83, 0x18, 0x00, 0x00, 0x01,
                              0x00, 0xFF, 0xFF,
                              0x00, 0x00, 0xFF,
                              0xFF, 0xFF, 0xFF,
                              0x00, 0x00, 0x01,
                              0x00, 0xFF, 0xFF,
                              0x00, 0x00, 0xFF,
                              0xFF, 0xFF, 0xFF ];

    my $p = $pkg->new($bytes, 0);
    ok($p, 'Got new EEG data value');
    is_deeply($p->as_bytes(), $bytes, 'Byte output is correct');
    is($p->length(), @{$bytes}, 'Byte length is correct');

    is($p->as_string(), 'EEG: delta=1, theta=65535, low alpha=255, high alpha=16777215, low beta=1, high beta=65535, low gamma=255, high gamma=16777215',
        'Stringification is correct');
    is_deeply($p->as_hashref(), { 'EEG.Delta'     => 1,
                                  'EEG.Theta'     => 65535,
                                  'EEG.LowAlpha'  => 255,
                                  'EEG.HighAlpha' => 16777215,
                                  'EEG.LowBeta'   => 1,
                                  'EEG.HighBeta'  => 65535,
                                  'EEG.LowGamma'  => 255,
                                  'EEG.HighGamma' => 16777215 },
        'Hashref output is correct');
}

1;
