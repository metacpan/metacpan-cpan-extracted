#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

package My::P1;
use Log::ger;

package main;

subtest "basics" => sub {
    my $ary = [];
    require Log::ger::Output;
    Log::ger::Output->set('Array', array => $ary);
    my $h = {}; Log::ger::init_target(hash => $h);

    is(ref $h, 'HASH');
    $h->{fatal}("fatal");
    $h->{error}("error");
    $h->{warn}("warn");
    $h->{info}("info");
    $h->{debug}("debug");
    $h->{trace}("trace");
    is_deeply($ary, [qw/fatal error warn/]);
};

done_testing;
