#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'MIDI::RtController::Filter';

subtest defaults => sub {
    my $obj = new_ok 'MIDI::RtController::Filter';
    is $obj->rtc, undef, 'rtc';
    is $obj->channel, 0, 'channel';
    is $obj->value, undef, 'value';
    is $obj->trigger, undef, 'trigger';
    is $obj->running, 0, 'running';
    is $obj->halt, 0, 'halt';
    is $obj->continue, 0, 'continue';
    ok !$obj->verbose, 'verbose';
};

done_testing();
