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

use IO::Capture::Stderr;
my $c = IO::Capture::Stderr->new();

sub make
{
    my ($suffix, @args) = @_;
    my $name = "Device::MindWave::Packet::".$suffix;
    return $name->new(@args);
}

{
    my $mwt = Device::MindWave::Tester->new();
    my $mw = Device::MindWave->new(fh => $mwt);

    $mwt->push_bytes([ (0x00) x 1000 ]);
    eval { $mw->read_packet(); };
    ok($@, 'Could not find synchronisation bytes');
    like($@, qr/Unable to find synchronisation bytes/,
        'Got correct error message');

    $mwt->push_bytes([ 0xAA, 0xAA, 0xFF ]);
    eval { $mw->read_packet(); };
    ok($@, 'Invalid length byte');
    like($@, qr/Length byte has invalid value/,
        'Got correct error message');

    $mwt->push_bytes([ 0xAA, 0xAA, 0x01, 0x00, 0x00 ]);
    eval { $mw->read_packet(); };
    ok($@, 'Checksum is invalid (retried, no bytes left)');
    like($@, qr/too few characters/,
        'Got correct error message');

    $mwt->push_bytes([ 0xAA, 0xAA, 0x04, 0x55, 0x55,
                       0x7F, 0x00, 0xD6 ]);
    $c->start();
    eval { $mw->read_packet(); };
    $c->stop();
    ok((not $@), 'Did not die on unhandled single-byte data value');
    diag $@ if $@;

    my @lines = $c->read();
    ok((grep { /Unhandled data value.*extended codes/ } @lines),
        'Found first warning (extended codes)');
    ok((grep { /Unhandled single-byte value code/ } @lines),
        'Found second warning (unhandled data value code)');

    $mwt->push_bytes([ 0xAA, 0xAA, 0x06, 0x55, 0x55,
                       0x81, 0x02, 0x00, 0x00, 0xD2 ]);
    $c->start();
    eval { $mw->read_packet(); };
    $c->stop();
    ok((not $@), 'Did not die on unhandled multi-byte data value');
    diag $@ if $@;

    @lines = $c->read();
    ok((grep { /Unhandled data value.*extended codes/ } @lines),
        'Found first warning (extended codes)');
    ok((grep { /Unhandled multi-byte value code/ } @lines),
        'Found second warning (unhandled data value code)');
}

1;
