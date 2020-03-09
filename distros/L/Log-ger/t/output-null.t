#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

package My::P1;
use Log::ger;

package main;

subtest "basics" => sub {
    Log::ger::Util::reset_hooks('create_outputter');
    require Log::ger::Output;
    Log::ger::Output->set('Null');
    my $h = {}; Log::ger::init_target(hash => $h);

    is(ref $h, 'HASH');
    $h->{fatal}("fatal");
    $h->{error}("error");
    $h->{warn}("warn");
    $h->{info}("info");
    $h->{debug}("debug");
    $h->{trace}("trace");
    ok(1);
};

done_testing;
