#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


my $eo = Evented::Object->new;
my ($lost, $won, $pending_bad, $pending_good);

# add a callback to cancel another
$eo->register_callback(hi => sub {
    shift->cancel('loser');
}, priority => 100);

# add a callback to check what's pending
$eo->register_callback(hi => sub {
    my $fire = shift;
    $won = 1;
    $pending_bad  = 1 if $fire->pending('loser');
    $pending_good = $fire->pending('pending_future');
});

# this one will be canceled
$eo->register_callback(hi => sub {
    $lost = 1;
}, name => 'loser');

# this one must still be pending
$eo->register_callback(hi => sub {
}, name => 'pending_future', priority => -5);

# fire the event
$eo->fire_event('hi');

# check that one was canceled and some were pending
isnt($lost, 1, 'cancel single callback');
is($won, 1, 'other callback still called');
isnt($pending_bad, 1, 'canceled callback is not still pending');
ok($pending_good, 'another callback still pending');


done_testing;
