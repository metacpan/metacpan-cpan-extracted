#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent;

use Test::More tests => 4;


use_ok('Fork::Promise');

my $fork = new_ok('Fork::Promise');

my $cv = AnyEvent->condvar();
$fork->run(sub {exit 0})
    ->then(sub {
        pass('run without fail');
        $cv->send();
    },
    sub {
        fail('run without fail');
        $cv->send();
    });
$cv->recv();

$cv = AnyEvent->condvar();
$fork->run(sub {exit 1})
    ->then(sub {
        fail('run with fail');
        $cv->send();
    },
    sub {
        pass('run with fail');
        $cv->send();
    });
$cv->recv();
