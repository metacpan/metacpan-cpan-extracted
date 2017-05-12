#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Evented::Object;


my @results;
my $eo = Evented::Object->new;

# add several callbacks which push to @results
$eo->register_callback(hi => sub { push @results, @_ })
    for 1..5;

# delete all callbacks then fire it
$eo->delete_event('hi');
$eo->fire_event('hi');

# better have no results
is(scalar @results, 0, 'deleting entire event');


done_testing;
