#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

package My::P1;
use Log::ger;

package My::P2;

package main;

subtest "opt:append_newline=1" => sub {
    my $str = "";
    Log::ger::Util::reset_hooks('create_outputter');
    require Log::ger::Output;
    Log::ger::Output->set('String', string => \$str, append_newline => 1);
    my $h = {}; Log::ger::init_target(hash => $h);

    is(ref $h, 'HASH');
    $h->{fatal}("fatal");
    $h->{error}("error");
    $h->{warn}("warn");
    $h->{info}("info");
    $h->{debug}("debug");
    $h->{trace}("trace");
    is($str, "fatal\nerror\nwarn\n");
};

subtest "opt:append_newline=0" => sub {
    my $str = "";
    Log::ger::Util::reset_hooks('create_outputter');
    require Log::ger::Output;
    Log::ger::Output->set('String', string => \$str, append_newline => 0);
    my $h = {}; Log::ger::init_target(hash => $h);

    is(ref $h, 'HASH');
    $h->{fatal}("fatal");
    $h->{error}("error");
    $h->{warn}("warn");
    $h->{info}("info");
    $h->{debug}("debug");
    $h->{trace}("trace");
    is($str, "fatalerrorwarn");
};

done_testing;
