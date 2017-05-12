#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


my $eo = Evented::Object->new;

# check that callback data works
$eo->register_callback(event => sub {
    is(shift->callback_data, 'my data', 'callback data');
}, data => 'my data');

$eo->fire_event('event');


done_testing;
