#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 27;

use Device::MindWave;
use Device::MindWave::Tester;
use Device::MindWave::Utils qw(packet_to_bytes);
use Device::MindWave::Packet::ThinkGear::DataValue::PoorSignal;

sub make
{
    my ($suffix, @args) = @_;
    my $name = "Device::MindWave::Packet::".$suffix;
    return $name->new(@args);
}

{
    eval { Device::MindWave->new() };
    ok($@, 'Died when neither port nor fh passed to constructor');
    like($@, qr/Either.*must be provided/,
        'Got correct error message');

    my $mwt = Device::MindWave::Tester->new();
    my $mw = Device::MindWave->new(fh => $mwt);

    # Successful connect.

    $mwt->push_packet(make('Dongle::StandbyMode'));
    $mwt->push_packet(make('Dongle::ScanMode'));
    $mwt->push_packet(make('Dongle::HeadsetFound',
                           [ 0xD0, 0x02, 0x12, 0x34 ], 0));

    eval { $mw->connect(0x12, 0x34); };
    ok((not $@), 'Connected to headset successfully');
    diag $@ if $@;

    # Successful disconnect.

    $mwt->push_packet(make('Dongle::HeadsetDisconnected',
                           [ 0xD2, 0x02, 0x12, 0x34 ], 0));
    eval { $mw->disconnect(); };
    ok((not $@), 'Disconnected from headset successfully');
    diag $@ if $@;

    # Successful auto-connect.

    $mwt->push_packet(make('Dongle::StandbyMode'));
    $mwt->push_packet(make('Dongle::StandbyMode'));
    $mwt->push_packet(make('Dongle::HeadsetFound',
                           [ 0xD0, 0x02, 0x12, 0x34 ], 0));
    eval { $mw->auto_connect(); };
    ok((not $@), 'Auto-connected to headset successfully');
    diag $@ if $@;

    # Successful implicit disconnect.

    $mwt->push_packet(make('Dongle::StandbyMode'));
    eval { $mw->disconnect(); };
    ok((not $@), 'Disconnected from headset successfully (implicit)');
    diag $@ if $@;

    $mwt->push_packet(make('Dongle::RequestDenied'));
    eval { $mw->disconnect(); };
    ok($@, 'Unable to disconnect (request denied)');
    like($@, qr/Request denied by dongle/, 'Got correct error message');

    # Headset not found.

    $mwt->push_packet(make('Dongle::StandbyMode'));
    $mwt->push_packet(make('Dongle::HeadsetNotFound',
                           [ 0xD1, 0x02, 0x12, 0x34 ], 0));
    eval { $mw->connect(0x1234); };
    ok($@, 'Unable to connect to headset (not found)');
    like($@, qr/Headset not found/,
        'Got correct error message');

    # Request denied.

    $mwt->push_packet(make('Dongle::StandbyMode'));
    $mwt->push_packet(make('Dongle::RequestDenied'));
    eval { $mw->connect(0x1234); };
    ok($@, 'Unable to connect to headset (request denied)');
    like($@, qr/Request denied/,
        'Got correct error message');

    # Headset not found (auto-connect).

    $mwt->push_packet(make('Dongle::StandbyMode'));
    $mwt->push_packet(make('Dongle::HeadsetNotFound',
                           [ 0xD1, 0x02, 0x12, 0x34 ], 0));
    eval { $mw->auto_connect(); };
    ok($@, 'Unable to auto-connect to headset (not found)');
    like($@, qr/No headset was found/,
        'Got correct error message');

    # Request denied (auto-connect).

    $mwt->push_packet(make('Dongle::StandbyMode'));
    $mwt->push_packet(make('Dongle::RequestDenied'));
    eval { $mw->auto_connect(); };
    ok($@, 'Unable to connect to headset (request denied)');
    like($@, qr/Request denied/,
        'Got correct error message');

    # Scan complete, no headset found.

    $Device::MindWave::_NO_SLEEP = 1;

    $mwt->push_packet(make('Dongle::StandbyMode'));
    for (1..10) {
        $mwt->push_packet(make('Dongle::ScanMode'));
    }
    for (1..5) {
        $mwt->push_packet(make('Dongle::StandbyMode'));
    }
    eval { $mw->connect(0x1234); };
    ok($@, 'Unable to connect to headset (scan completed)');
    like($@, qr/Unable to connect to headset/,
        'Got correct error message');

    # Unable to read standby packet.

    for (1..15) {
        $mwt->push_packet(make('Dongle::ScanMode'));
    }
    eval { $mw->connect(0x1234); };
    ok($@, 'Unable to connect to headset (no standby)');
    like($@, qr/Timed out waiting for standby/,
        'Got correct error message');

    # Two errors on disconnect (no sync bytes found, and invalid
    # length) equals failure.

    $mwt->push_packet(make('Dongle::StandbyMode'));
    $mwt->push_packet(make('Dongle::HeadsetFound',
                           [ 0xD0, 0x02, 0x12, 0x34 ], 0));
    eval { $mw->connect(0x1234); };
    ok((not $@), 'Connected to headset successfully');
    diag $@ if $@;

    my $ps =
        Device::MindWave::Packet::ThinkGear::DataValue::PoorSignal->new(
            [ 0x02, 0x2F ], 0
        );
    my $tg = Device::MindWave::Packet::ThinkGear->new([], 0);
    $tg->{'data_values'} = [ $ps ];
    $mwt->push_packet($tg);
    $mwt->push_bytes([ 0xAA, 0x01, 0xAA, (0x01) x 1000 ]);
    $mwt->push_bytes([ 0xAA, 0xAA, 0xFE ]);
    eval { $mw->disconnect(); };
    ok($@, 'Unable to disconnect from headset (got two errors)');
    like($@, qr/Length byte has invalid value \(254\)/,
        'Got correct error message');

    # Unable to disconnect (timed out).

    for (1..15) {
        $mwt->push_packet(make('Dongle::ScanMode'));
    }
    eval { $mw->disconnect(); };
    ok($@, 'Unable to disconnect from headset (timed out)');
    like($@, qr/Unable to disconnect from headset/,
        'Got correct error message');

    # Unable to auto-connect (timed out).

    $mwt->push_packet(make('Dongle::StandbyMode'));
    for (1..15) {
        $mwt->push_packet(make('Dongle::ScanMode'));
    }
    eval { $mw->auto_connect(); };
    ok($@, 'Unable to auto-connect to any headset (timed out)');
    like($@, qr/Unable to connect to any headset/,
        'Got correct error message');
}

1;
