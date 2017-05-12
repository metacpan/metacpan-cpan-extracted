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

# add two cbs, one on the cow and one on the farm
$cow->on(moo => sub {
    my $fire = shift;
    $fire->stop;
}, priority => 200, name => 'no');

$farm->on('cow.moo' => sub {
    my $fire = shift;
    fail('event stopped');
}, priority => -100, name => 'yes');

# fire the event which will fail if ->Stop didn't work
$cow->fire_event('moo');
pass('event stopped');


done_testing;
