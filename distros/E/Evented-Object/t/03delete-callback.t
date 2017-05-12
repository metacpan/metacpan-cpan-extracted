#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


# tests deleting a single callback.
# ensures only that specific callback is deleted.
my $eo = Evented::Object->new;
my ($lost, $won);

# add two callbacks, one which will be deleted
$eo->register_callback(hi => sub {
    $won = 1;
}, priority => 100);

$eo->register_callback(hi => sub {
    $lost = 1;
}, name => 'loser');

# delete one of them and fire
$eo->delete_callback('hi', 'loser');
$eo->fire_event('hi');

# make sure one was called and one was not
isnt($lost, 1, 'deleted single callback');
is($won, 1, 'other callback still called');


done_testing;
