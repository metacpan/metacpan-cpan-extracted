#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


my @results;
my $eo = Evented::Object->new;
my $cb = sub { push @results, shift->callback_name };

# add callbacks with befores and afters that cannot be resolved
$eo->register_callback(event => $cb, name => 'unresolvable1',
    before => 'first', after => ['fourth', 'unresolvable2']);
$eo->register_callback(event => $cb, name => 'unresolvable2',
    before => ['first', 'unresolvable1'], after => 'fourth');

# fire the event
$eo->fire_event('event');
pass('unresolvable priorities ok');


done_testing;
