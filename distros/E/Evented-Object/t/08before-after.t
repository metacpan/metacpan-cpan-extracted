#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


my $eo = Evented::Object->new;
my ($first, $second);

# add a cb which has a high priority
$eo->register_callback(hi => sub {
    $first = 1;
}, priority => 50, name => 'main');

# add a cb which has an even higher priority with 'before'
$eo->register_callback(hi => sub {
    ok(!$first, 'before callback should be called first');
    $second = 1;
}, before => 'main');

# add a cb which has a lower priority with 'after'
$eo->register_callback(hi => sub {
    ok($first, 'after callback should be called after');
}, after => 'main');

# fire and check that the order is correct
$eo->fire_event('hi');


done_testing;
