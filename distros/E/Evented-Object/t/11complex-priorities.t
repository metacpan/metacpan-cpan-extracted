#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


my @results;
my $eo = Evented::Object->new;

# add several callbacks with complex befores and afters to resolve
my $cb = sub { push @results, shift->callback_name };
$eo->register_callback(event => $cb, name => 'third');
$eo->register_callback(event => $cb, name => 'second', before => 'third');
$eo->register_callback(event => $cb, name => 'first',  before => ['second', 'third']);
$eo->register_callback(event => $cb, name => 'fourth', after  => ['first', 'third']);

# fire the event
$eo->fire_event('event');

# make sure they occurred in the correct order
is($results[0], 'first',  'complex before and afters');
is($results[1], 'second', 'complex before and afters');
is($results[2], 'third',  'complex before and afters');
is($results[3], 'fourth', 'complex before and afters');


done_testing;
