#!perl

use strict;
use warnings;
use Test::More 0.98;

use Capture::Tiny 'capture';
use Log::ger::Util;

package My::P1;
use Log::ger;

package My::P2;

package main;

subtest "basics" => sub {
    my $str = "";
    Log::ger::Util::reset_plugins('create_log_routine');
    require Log::ger::Output;
    Log::ger::Output->set('Screen');
    my $h = Log::ger::setup_hash();

    my ($stdout, $stderr, $exit) = capture {
        $h->{log_fatal}("fatal");
        $h->{log_error}("error");
        $h->{log_warn}("warn");
        $h->{log_info}("info");
        $h->{log_debug}("debug");
        $h->{log_trace}("trace");
    };
    is($stderr, "fatal\nerror\nwarn\n");
    is($stdout, "");

    Log::ger::Util::set_level(1);
    $h = Log::ger::setup_hash();

    ($stdout, $stderr, $exit) = capture {
        $h->{log_fatal}("fatal");
        $h->{log_error}("error");
        $h->{log_warn}("warn");
        $h->{log_info}("info");
        $h->{log_debug}("debug");
        $h->{log_trace}("trace");
    };
    is($stderr, "fatal\n");
    is($stdout, "");

    subtest "opt:use_color=1" => sub {
        Log::ger::Output->set('Screen', use_color=>1);
        my $h = Log::ger::setup_hash();
        ($stdout, $stderr, $exit) = capture {
            $h->{log_fatal}("fatal");
        };
        is($stderr, "\e[31mfatal\e[0m\n");
    };

    subtest "opt:stderr=0" => sub {
        Log::ger::Output->set('Screen', stderr => 0);
        my $h = Log::ger::setup_hash();
        ($stdout, $stderr, $exit) = capture {
            $h->{log_fatal}("fatal");
            $h->{log_error}("error");
            $h->{log_warn}("warn");
            $h->{log_info}("info");
            $h->{log_debug}("debug");
            $h->{log_trace}("trace");
        };
        is($stderr, "");
        is($stdout, "fatal\n");
    };
};

# XXX test formatter option

done_testing;
