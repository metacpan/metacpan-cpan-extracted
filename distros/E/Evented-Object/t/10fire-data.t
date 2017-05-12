#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


my $eo = Evented::Object->new;

# check that the fire data is right
$eo->register_callback(event => sub {
    my $fire = shift;
    is($fire->data, 'some data', 'fire with data');
});

$eo->prepare('event')->fire(data => 'some data');
$eo->delete_all_events;

# check that ->data returns 'data' key and that ->data(key) returns other keys
$eo->register_callback(event => sub {
    my $fire = shift;
    is($fire->data, 'the data key', '->data equals fire data {data} key');
    is($fire->data('other key'), 'another value', '->data(key) equals fire data {key}');
});

$eo->prepare('event')->fire(data => {
    data        => 'the data key',
    'other key' => 'another value'
});


done_testing;
