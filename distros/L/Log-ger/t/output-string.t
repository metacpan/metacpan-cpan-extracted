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
    Log::ger::Util::reset_plugins('create_log_routine');
    require Log::ger::Output;
    Log::ger::Output->set('String', string => \$str, append_newline => 1);
    my $h = Log::ger::setup_hash();

    is(ref $h, 'HASH');
    $h->{log_fatal}("fatal");
    $h->{log_error}("error");
    $h->{log_warn}("warn");
    $h->{log_info}("info");
    $h->{log_debug}("debug");
    $h->{log_trace}("trace");
    is($str, "fatal\nerror\nwarn\n");
};

subtest "opt:append_newline=0" => sub {
    my $str = "";
    Log::ger::Util::reset_plugins('create_log_routine');
    require Log::ger::Output;
    Log::ger::Output->set('String', string => \$str, append_newline => 0);
    my $h = Log::ger::setup_hash();

    is(ref $h, 'HASH');
    $h->{log_fatal}("fatal");
    $h->{log_error}("error");
    $h->{log_warn}("warn");
    $h->{log_info}("info");
    $h->{log_debug}("debug");
    $h->{log_trace}("trace");
    is($str, "fatalerrorwarn");
};

done_testing;
