#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


# create two evented objects
my $farm = Evented::Object->new;
my $cow  = Evented::Object->new;

# make one a listener of the other
$cow->add_listener($farm, 'cow');

# check metadata for a normal cb
$cow->on(moo => sub {
    my $fire = shift;
    is($fire->event_name, 'moo', 'event name is moo');
    is($fire->object, $cow, 'evented object is cow');
    is($fire->callback_name, 'no', 'callback name is no');
}, priority => 200, name => 'no');

# check metadata for a listener cb
$farm->on('cow.moo' => sub {
    my $fire = shift;
    is($fire->event_name, 'cow.moo', 'event name is cow.moo');
    is($fire->object, $cow, 'evented object is cow');
    is($fire->callback_name, 'yes', 'callback name is yes');
}, priority => -100, name => 'yes');

$cow->fire_event('moo');


done_testing;
