#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::RtController';

SKIP: {
    skip 'live test', 7;
    my $obj = new_ok 'MIDI::RtController' => [
        input  => 'tempopad',
        output => 'fluid',
    ];
    is $obj->verbose, 0, 'verbose';
    isa_ok $obj->loop, 'IO::Async::Loop';
    is_deeply $obj->filters, {}, 'filters';
    isa_ok $obj->_msg_channel, 'IO::Async::Channel';
    isa_ok $obj->_midi_channel, 'IO::Async::Channel';
    isa_ok $obj->midi_out, 'MIDI::RtMidi::FFI::Device';
};

done_testing();
