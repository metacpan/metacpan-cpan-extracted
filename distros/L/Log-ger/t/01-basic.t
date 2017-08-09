#!perl

use strict;
use warnings;
use Test::More 0.98;

package My::P1;
use Log::ger;
BEGIN { log_trace(""); } # just to test that sub exists

package My::P2;

package My::P3; # test get_logger
use Log::ger ();
BEGIN { my $log = Log::ger->get_logger; $log->trace(""); } # just to test that method exists

package main;
use Log::ger::Util;

subtest numeric_level => sub {
    is(Log::ger::Util::numeric_level(10), 10);
    is(Log::ger::Util::numeric_level("info"), 40);
    # XXX check unknown level
};

subtest string_level => sub {
    is(Log::ger::Util::string_level(10), "fatal");
    is(Log::ger::Util::string_level("info"), "info");
    is(Log::ger::Util::string_level("warning"), "warn");
    # XXX check unknown level
};

subtest "basics" => sub {
    subtest "import" => sub {
        my $str = "";
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);

        My::P1::log_warn("warn");
        My::P1::log_debug("debug");
        is($str, "warn\n");
        {
            $str = "";
            Log::ger::Util::set_level(50);
            My::P1::log_warn("warn");
            My::P1::log_debug("debug");
            is($str, "warn\ndebug\n");
        }
    };

    subtest "init_target package" => sub {
        my $str = "";
        Log::ger::Util::set_level(30);
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);
        Log::ger::init_target(package => 'My::P2');
        My::P2::log_warn("warn");
        My::P2::log_debug("debug");
        is($str, "warn\n");
    };

    subtest "init_target hash" => sub {
        my $str = "";
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);
        Log::ger::Util::set_level(30);
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

    subtest "init_target object" => sub {
        my $str = "";
        require Log::ger::Output;
        Log::ger::Output->set('String', string => \$str);
        Log::ger::Util::set_level(30);
        my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);

        $o->fatal("fatal");
        $o->error("error");
        $o->warn("warn");
        $o->info("info");
        $o->debug("debug");
        $o->trace("trace");
        is($str, "fatal\nerror\nwarn\n");

        subtest "level=off (0)" => sub {
            $str = "";
            Log::ger::Util::set_level(0);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "");
        };
        subtest "level=fatal (10)" => sub {
            $str = "";
            Log::ger::Util::set_level(10);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\n");
        };
        subtest "level=error (20)" => sub {
            $str = "";
            Log::ger::Util::set_level(20);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\nerror\n");
        };
        subtest "level=info (40)" => sub {
            $str = "";
            Log::ger::Util::set_level(40);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\nerror\nwarn\ninfo\n");
        };
        subtest "level=debug (50)" => sub {
            $str = "";
            Log::ger::Util::set_level(50);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\nerror\nwarn\ninfo\ndebug\n");
        };
        subtest "level=trace (60)" => sub {
            $str = "";
            Log::ger::Util::set_level(60);
            my $o = bless [], "My::Logger"; Log::ger::init_target(object => $o);
            $o->fatal("fatal");
            $o->error("error");
            $o->warn("warn");
            $o->info("info");
            $o->debug("debug");
            $o->trace("trace");
            is($str, "fatal\nerror\nwarn\ninfo\ndebug\ntrace\n");
        };
    };
};

subtest "switch output" => sub {
    require Log::ger::Output;
    my $str = "";
    my $ary = [];
    my $h = {};
    Log::ger::add_target(hash => $h);

    Log::ger::Output->set('String', string => \$str);
    $h->{warn}("warn1");
    is_deeply($str, "warn1\n");
    is_deeply($ary, []);

    Log::ger::Output->set('ArrayML', array => $ary);
    $h->{warn}("warn2");
    is_deeply($str, "warn1\n");
    is_deeply($ary, ["warn2"]);

    Log::ger::Output->set('String', string => \$str);
    $h->{warn}("warn3");
    is_deeply($str, "warn1\nwarn3\n");
    is_deeply($ary, ["warn2"]);

    Log::ger::Output->set('ArrayML', array => $ary);
    $h->{warn}("warn4");
    is_deeply($str, "warn1\nwarn3\n");
    is_deeply($ary, ["warn2", "warn4"]);
};

DONE_TESTING:
done_testing;
