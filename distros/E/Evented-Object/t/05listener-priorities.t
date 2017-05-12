#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


# create two evented objects
my @results;
my $farm = Evented::Object->new;
my $cow  = Evented::Object->new;

# make one a listener of the other
$cow->add_listener($farm, 'cow');

# add a cb directly to the cow
$cow->on('moo' => sub {
    push @results, 'l200';
}, priority => 200);

# add a cb for the cow to the farm
$farm->on('cow.moo' => sub {
    push @results, -100;
}, priority => -100);

# add another to the cow for testing priorities
$cow->on('moo' => sub {
    push @results, 50;
}, priority => 50);

# add another to the farm for testing priorities
$farm->on('cow.moo' => sub {
    push @results, 'l100';
}, priority => 100);

# fire event
$cow->fire_event('moo');

# make sure they occurred in the correct order
is($results[0], 'l200', '200 priority should be called first');
is($results[1], 'l100', '100 priority should be called second');
is($results[2], 50,     '50 priority should be called third');
is($results[3], -100,   '-100 priority should be called fourth');


done_testing;
