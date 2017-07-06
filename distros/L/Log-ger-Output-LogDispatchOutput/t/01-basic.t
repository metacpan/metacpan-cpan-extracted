#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Output ();

package My::P1;
use Log::ger;

package main;

subtest "basics" => sub {
    my $ary = [];
    Log::ger::Output->set(
        'LogDispatchOutput',
        output => 'ArrayWithLimits',
        args => {array => $ary},
    );
    my $h = {}; Log::ger::init_target(hash => $h);

    $h->{warn}("warn");
    $h->{error}("error");
    $h->{debug}("debug");
    is_deeply($ary, ["warn", "error"]);
};

done_testing;
