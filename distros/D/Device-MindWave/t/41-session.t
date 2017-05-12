#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 12;

use Device::MindWave;
use Device::MindWave::Tester;
use Device::MindWave::Utils qw(packet_to_bytes
                               packet_isa);
use Device::MindWave::Packet::ThinkGear::DataValue::PoorSignal;

sub make
{
    my ($suffix, @args) = @_;
    my $name = "Device::MindWave::Packet::".$suffix;
    return $name->new(@args);
}

{
    my $mwt = Device::MindWave::Tester->new();
    my $mw = Device::MindWave->new(fh => $mwt);

    $mwt->push_packet(make('Dongle::StandbyMode'));
    $mwt->push_packet(make('Dongle::ScanMode'));
    $mwt->push_packet(make('Dongle::HeadsetFound',
                           [ 0xD0, 0x02, 0x12, 0x34 ], 0));

    eval { $mw->connect(0x1234); };
    ok((not $@), 'Connected to headset successfully');
    diag $@ if $@;

    my @dvs = (
        make('ThinkGear::DataValue::PoorSignal',
            [ 0x02, 0x01 ], 0),
        make('ThinkGear::DataValue::Attention',
            [ 0x02, 0x02 ], 0),
        make('ThinkGear::DataValue::Meditation',
            [ 0x05, 0x03 ], 0),
        make('ThinkGear::DataValue::BlinkStrength',
            [ 0x16, 0x04 ], 0),
        make('ThinkGear::DataValue::RawWave',
            [ 0x80, 0x02, 0x12, 0x34 ], 0)
    );
    my $tg = Device::MindWave::Packet::ThinkGear->new([], 0);
    $tg->{'data_values'} = \@dvs;
    $mwt->push_packet($tg);

    my $p = $mw->read_packet();
    ok(packet_isa($p, 'ThinkGear'),
        'Got ThinkGear packet');
    my $ndv = $p->next_data_value();
    ok(packet_isa($ndv, 'ThinkGear::DataValue::PoorSignal'),
        'Got poor signal data value');
    $ndv = $p->next_data_value();
    ok(packet_isa($ndv, 'ThinkGear::DataValue::Attention'),
        'Got attention data value');
    $ndv = $p->next_data_value();
    ok(packet_isa($ndv, 'ThinkGear::DataValue::Meditation'),
        'Got meditation data value');
    $ndv = $p->next_data_value();
    ok(packet_isa($ndv, 'ThinkGear::DataValue::BlinkStrength'),
        'Got blink strength data value');
    $ndv = $p->next_data_value();
    ok(packet_isa($ndv, 'ThinkGear::DataValue::RawWave'),
        'Got raw wave data value');
    is($p->next_data_value(), undef,
        'No more data values left');

    is($p->length(), 12, 'Got correct length from TG packet');
    is_deeply($p->as_hashref(),
              { Attention     => 2,
                PoorSignal    => 1,
                Meditation    => 3,
                BlinkStrength => 4,
                RawWave       => 4660 },
              'Hashref output is correct');
    is($p->as_string(), 'Poor signal (1/200); Attention (2/100); '.
                        'Meditation (3/100); Blink strength (4/255); '.
                        'Raw wave: 4660',
        'Stringification is correct');

    $mwt->push_packet(make('Dongle::HeadsetDisconnected',
                           [ 0xD2, 0x02, 0x12, 0x34 ], 0));

    eval { $mw->disconnect(); };
    ok((not $@), 'Disconnected from headset successfully');
    diag $@ if $@;
}

1;
