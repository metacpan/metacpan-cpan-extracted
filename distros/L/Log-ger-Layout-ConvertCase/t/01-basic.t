#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Layout ();

use vars '$ary'; BEGIN { $ary = [] }
use Log::ger::Output 'Array', array => $ary;

package My::P1;
use Log::ger;

sub x {
    log_warn("Hello, World");
}

package main;

subtest "basics" => sub {
    Log::ger::Layout->set(ConvertCase => (case=>'upper'));
    splice @$ary;
    My::P1::x();
    is_deeply($ary, ["HELLO, WORLD"]);

    Log::ger::Layout->set(ConvertCase => (case=>'lower'));
    splice @$ary;
    My::P1::x();
    is_deeply($ary, ["hello, world"]);
};

done_testing;
