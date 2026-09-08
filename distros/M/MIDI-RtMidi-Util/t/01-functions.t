#!/usr/bin/env perl

use Test::More;
use Test::Exception;

BEGIN {
    use_ok 'MIDI::RtMidi::Util', qw(
        in_port out_port stop_device input_ports output_ports
    );
}

subtest throws => sub {
    throws_ok { in_port() }
        qr/Too few arguments/,
        'in_port() dies without port name';
    throws_ok { out_port() }
        qr/Too few arguments/,
        'out_port() dies without port name';
    throws_ok { stop_device() }
        qr/Too few arguments/,
        'stop_device() dies without a port';
};

subtest defaults => sub {
    my $got = input_ports();
    is ref($got), 'ARRAY', 'input_ports';
    $got = output_ports();
    is ref($got), 'ARRAY', 'output_ports';
};

done_testing();
