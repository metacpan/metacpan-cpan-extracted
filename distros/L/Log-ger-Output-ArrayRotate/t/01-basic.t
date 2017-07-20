#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

package My::P1;
use Log::ger;

package My::P2;

package main;

subtest "opt:max_elems" => sub {
    my $ary = [];
    Log::ger::Util::reset_hooks('create_log_routine');
    require Log::ger::Output;
    Log::ger::Output->set('ArrayRotate', array => $ary, max_elems => 3);
    my $h = {}; Log::ger::init_target(hash => $h);

    $h->{warn}(1);
    $h->{warn}(2);
    $h->{warn}(3);
    is_deeply($ary, [1,2,3]);
    $h->{warn}(4);
    is_deeply($ary, [2,3,4]);
};

done_testing;
