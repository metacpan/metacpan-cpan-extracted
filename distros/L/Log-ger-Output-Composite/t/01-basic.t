#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

package My::P1;
use Log::ger;

package main;

subtest "basics" => sub {
    my $str1 = "";
    my $str2 = "";
    Log::ger::Util::reset_plugins('create_log_routine');
    require Log::ger::Output;
    Log::ger::Output->set('Composite', outputs=>{String=>[ {args=>{string=>\$str1}}, {args=>{string=>\$str2}} ]});
    My::P1::log_warn("warn");
    My::P1::log_debug("debug");
    is($str1, "warn\n");
    is($str2, "warn\n");
};

subtest "per-output level" => sub {
    my $str1 = "";
    my $str2 = "";
    my $str3 = "";
    Log::ger::Util::reset_plugins('create_log_routine');
    require Log::ger::Output;
    Log::ger::Output->set('Composite', outputs=>{String=>[ {args=>{string=>\$str1}}, {level=>"info", args=>{string=>\$str2}}, {level=>"error", args=>{string=>\$str3}} ]});
    My::P1::log_debug("debug");
    My::P1::log_info("info");
    My::P1::log_warn("warn");
    My::P1::log_error("error");
    is($str1, "warn\nerror\n");
    is($str2, "info\nwarn\nerror\n");
    is($str3, "error\n");

    $str1 = $str2 = $str3 = "";
    Log::ger::Util::set_level("info");
    My::P1::log_debug("debug");
    My::P1::log_info("info");
    My::P1::log_warn("warn");
    My::P1::log_error("error");
    is($str1, "info\nwarn\nerror\n");
    is($str2, "info\nwarn\nerror\n");
    is($str3, "error\n");
};

# XXX test filtering: per-output per-category level
# XXX test filtering: per-category level

done_testing;
