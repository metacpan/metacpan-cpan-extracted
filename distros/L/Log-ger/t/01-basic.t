#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

package My::P1;
use Log::ger;

package My::P2;

package main;

subtest "basics" => sub {
    subtest "import" => sub {
        my $str = "";
        Log::ger::Util::reset_plugins('create_log_routine');
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);

        My::P1::log_warn("warn");
        My::P1::log_debug("debug");
        is($str, "warn\n");

        {
            $str = "";
            Log::ger::Util::set_level(5);
            My::P1::log_warn("warn");
            My::P1::log_debug("debug");
            is($str, "warn\ndebug\n");
        }
    };

    subtest "setup_package" => sub {
        my $str = "";
        Log::ger::Util::reset_plugins('create_log_routine');
        Log::ger::Util::set_level(3);
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);
        Log::ger::setup_package('My::P2');
        My::P2::log_warn("warn");
        My::P2::log_debug("debug");
        is($str, "warn\n");
    };

    subtest "setup_hash" => sub {
        my $str = "";
        Log::ger::Util::reset_plugins('create_log_routine');
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);
        Log::ger::Util::set_level(3);
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

    subtest "setup_object" => sub {
        my $str = "";
        Log::ger::Util::reset_plugins('create_log_routine');
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);
        Log::ger::Util::set_level(3);
        my $o = Log::ger::setup_object();

        $o->log_fatal("fatal");
        $o->log_error("error");
        $o->log_warn("warn");
        $o->log_info("info");
        $o->log_debug("debug");
        $o->log_trace("trace");
        is($str, "fatal\nerror\nwarn\n");

        subtest "level=off (0)" => sub {
            $str = "";
            Log::ger::Util::set_level(0);
            $o = Log::ger::setup_object();
            $o->log_fatal("fatal");
            $o->log_error("error");
            $o->log_warn("warn");
            $o->log_info("info");
            $o->log_debug("debug");
            $o->log_trace("trace");
            is($str, "");
        };
        subtest "level=fatal (1)" => sub {
            $str = "";
            Log::ger::Util::set_level(1);
            $o = Log::ger::setup_object();
            $o->log_fatal("fatal");
            $o->log_error("error");
            $o->log_warn("warn");
            $o->log_info("info");
            $o->log_debug("debug");
            $o->log_trace("trace");
            is($str, "fatal\n");
        };
        subtest "level=error (2)" => sub {
            $str = "";
            Log::ger::Util::set_level(2);
            $o = Log::ger::setup_object();
            $o->log_fatal("fatal");
            $o->log_error("error");
            $o->log_warn("warn");
            $o->log_info("info");
            $o->log_debug("debug");
            $o->log_trace("trace");
            is($str, "fatal\nerror\n");
        };
        subtest "level=info (4)" => sub {
            $str = "";
            Log::ger::Util::set_level(4);
            $o = Log::ger::setup_object();
            $o->log_fatal("fatal");
            $o->log_error("error");
            $o->log_warn("warn");
            $o->log_info("info");
            $o->log_debug("debug");
            $o->log_trace("trace");
            is($str, "fatal\nerror\nwarn\ninfo\n");
        };
        subtest "level=debug (5)" => sub {
            $str = "";
            Log::ger::Util::set_level(5);
            $o = Log::ger::setup_object();
            $o->log_fatal("fatal");
            $o->log_error("error");
            $o->log_warn("warn");
            $o->log_info("info");
            $o->log_debug("debug");
            $o->log_trace("trace");
            is($str, "fatal\nerror\nwarn\ninfo\ndebug\n");
        };
        subtest "level=trace (6)" => sub {
            $str = "";
            Log::ger::Util::set_level(6);
            $o = Log::ger::setup_object();
            $o->log_fatal("fatal");
            $o->log_error("error");
            $o->log_warn("warn");
            $o->log_info("info");
            $o->log_debug("debug");
            $o->log_trace("trace");
            is($str, "fatal\nerror\nwarn\ninfo\ndebug\ntrace\n");
        };
    };
};

done_testing;
