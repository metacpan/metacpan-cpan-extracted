#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


# tests basic priorities
my @results;
my $eo = Evented::Object->new;

# add several callbacks which push numbers to @results
$eo->register_callback(hi => sub {
    push @results, 100;
}, priority => 100);

$eo->register_callback(hi => sub {
    push @results, 200;
}, priority => 200);

$eo->register_callback(hi => sub {
    push @results, -5;
}, priority => -5);

$eo->register_callback(hi => sub {
    push @results, 0;
});

# fire the event
$eo->fire_event('hi');

# check that things were pushed in the correct order
is($results[0], 200, '200 priority should be called first');
is($results[1], 100, '100 priority should be called second');
is($results[2], 0,   '0 priority should be called third');
is($results[3], -5,  '-5 priority should be called fourth');


done_testing;
