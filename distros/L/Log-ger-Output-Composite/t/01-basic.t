#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Output ();
use Log::ger::Util;

package My::P1; use Log::ger;
package My::P1::P2; use Log::ger;
package My::P1::P2::P3; use Log::ger;
package My::P1::P4; use Log::ger;
package My::P5; use Log::ger;
package My::P6; use Log::ger;

package main;

subtest "basics" => sub {
    my $str1 = "";
    my $str2 = "";
    Log::ger::Output->set(
        'Composite',
        outputs=>{
            String=>[
                {conf=>{string=>\$str1}},
                {conf=>{string=>\$str2}},
            ],
        });
    My::P1::log_warn("warn");
    My::P1::log_debug("debug");
    is($str1, "warn\n");
    is($str2, "warn\n");
};

subtest "per-output level" => sub {
    my $str1 = "";
    my $str2 = "";
    my $str3 = "";
    Log::ger::Output->set(
        'Composite',
        outputs=>{
            String=>[
                {conf=>{string=>\$str1}},
                {level=>"info", conf=>{string=>\$str2}},
                {level=>"error", conf=>{string=>\$str3}},
            ],
        });
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

subtest "per-output min & max level" => sub {
    my $str1 = "";
    my $str2 = "";
    my $str3 = "";
    Log::ger::Output->set(
        'Composite',
        outputs=>{
            String=>[
                {conf=>{string=>\$str1}},
                {level=>["debug", "info"], conf=>{string=>\$str2}},
                {level=>["fatal", "error"], conf=>{string=>\$str3}},
            ],
        });
    Log::ger::Util::set_level("warn");
    My::P1::log_trace("trace");
    My::P1::log_debug("debug");
    My::P1::log_info("info");
    My::P1::log_warn("warn");
    My::P1::log_error("error");
    My::P1::log_fatal("fatal");
    is($str1, "warn\nerror\nfatal\n");
    is($str2, "debug\ninfo\n");
    is($str3, "error\nfatal\n");
};

subtest "per-category level" => sub {
    my $str1 = "";
    Log::ger::Output->set(
        'Composite',
        category_level => {
            'My::P1' => 'debug',
            'My::P1::P2' => 'fatal',
            'My::P1::P4' => 'info',
            'My::P5' => 'error',
            'My::P7' => 'trace',
        },
        outputs=>{
            String=>[
                {
                    conf => {string=>\$str1},
                },
            ],
        });
    Log::ger::Util::set_level("warn");
    for my $pkg (qw/My::P1 My::P1::P2 My::P1::P2::P3 My::P1::P4 My::P5 My::P6/) {
        no strict 'refs';
        &{"$pkg\::log_trace"}("trace $pkg");
        &{"$pkg\::log_debug"}("debug $pkg");
        &{"$pkg\::log_info"}("info $pkg");
        &{"$pkg\::log_warn"}("warn $pkg");
        &{"$pkg\::log_error"}("error $pkg");
        &{"$pkg\::log_fatal"}("fatal $pkg");
    }
    is($str1,
       join(
           "",
           "debug My::P1\ninfo My::P1\nwarn My::P1\nerror My::P1\nfatal My::P1\n",
           "fatal My::P1::P2\n",
           "fatal My::P1::P2::P3\n",
           "info My::P1::P4\nwarn My::P1::P4\nerror My::P1::P4\nfatal My::P1::P4\n",
           "error My::P5\nfatal My::P5\n",
           "warn My::P6\nerror My::P6\nfatal My::P6\n",
       ));
};

subtest "per-output, per-category level" => sub {
    my $str1 = "";
    Log::ger::Output->set(
        'Composite',
        outputs=>{
            String=>[
                {
                    conf => {string=>\$str1},
                    category_level => {
                        'My::P1' => 'debug',
                        'My::P1::P2' => 'fatal',
                        'My::P1::P4' => 'info',
                        'My::P5' => 'error',
                        'My::P7' => 'trace',
                    },
                },
            ],
        });
    Log::ger::Util::set_level("warn");
    for my $pkg (qw/My::P1 My::P1::P2 My::P1::P2::P3 My::P1::P4 My::P5 My::P6/) {
        no strict 'refs';
        &{"$pkg\::log_trace"}("trace $pkg");
        &{"$pkg\::log_debug"}("debug $pkg");
        &{"$pkg\::log_info"}("info $pkg");
        &{"$pkg\::log_warn"}("warn $pkg");
        &{"$pkg\::log_error"}("error $pkg");
        &{"$pkg\::log_fatal"}("fatal $pkg");
    }
    is($str1,
       join(
           "",
           "debug My::P1\ninfo My::P1\nwarn My::P1\nerror My::P1\nfatal My::P1\n",
           "fatal My::P1::P2\n",
           "fatal My::P1::P2::P3\n",
           "info My::P1::P4\nwarn My::P1::P4\nerror My::P1::P4\nfatal My::P1::P4\n",
           "error My::P5\nfatal My::P5\n",
           "warn My::P6\nerror My::P6\nfatal My::P6\n",
       ));

    # per-output per-category level vs general level
    $str1 = "";
    Log::ger::Util::set_level("debug");
    for my $pkg (qw/My::P1 My::P1::P2 My::P1::P2::P3 My::P1::P4 My::P5 My::P6/) {
        no strict 'refs';
        &{"$pkg\::log_trace"}("trace $pkg");
        &{"$pkg\::log_debug"}("debug $pkg");
        &{"$pkg\::log_info"}("info $pkg");
        &{"$pkg\::log_warn"}("warn $pkg");
        &{"$pkg\::log_error"}("error $pkg");
        &{"$pkg\::log_fatal"}("fatal $pkg");
    }
    is($str1,
       join(
           "",
           "debug My::P1\ninfo My::P1\nwarn My::P1\nerror My::P1\nfatal My::P1\n",
           "fatal My::P1::P2\n",
           "fatal My::P1::P2::P3\n",
           "info My::P1::P4\nwarn My::P1::P4\nerror My::P1::P4\nfatal My::P1::P4\n",
           "error My::P5\nfatal My::P5\n",
           "debug My::P6\ninfo My::P6\nwarn My::P6\nerror My::P6\nfatal My::P6\n",
       ));

    # per-output per-category level vs per-category level
    Log::ger::Output->set(
        'Composite',
        category_level => {
            'My::P1' => 'debug',
            'My::P1::P2' => 'fatal',
            'My::P1::P4' => 'info',
            'My::P5' => 'error',
            'My::P7' => 'trace',
        },
        outputs=>{
            String=>[
                {
                    conf => {string=>\$str1},
                    category_level => {
                        'My::P1' => 'fatal',
                    },
                },
            ],
        });
    $str1 = "";
    Log::ger::Util::set_level("warn");
    for my $pkg (qw/My::P1 My::P1::P2 My::P1::P2::P3 My::P1::P4 My::P5 My::P6/) {
        no strict 'refs';
        &{"$pkg\::log_trace"}("trace $pkg");
        &{"$pkg\::log_debug"}("debug $pkg");
        &{"$pkg\::log_info"}("info $pkg");
        &{"$pkg\::log_warn"}("warn $pkg");
        &{"$pkg\::log_error"}("error $pkg");
        &{"$pkg\::log_fatal"}("fatal $pkg");
    }
    is($str1,
       join(
           "",
           "fatal My::P1\n",
           "fatal My::P1::P2\n",
           "fatal My::P1::P2::P3\n",
           "info My::P1::P4\nwarn My::P1::P4\nerror My::P1::P4\nfatal My::P1::P4\n",
           "error My::P5\nfatal My::P5\n",
           "warn My::P6\nerror My::P6\nfatal My::P6\n",
       ));

};

subtest "per-output layout" => sub {
    my $str1 = "";
    my $str2 = "";
    Log::ger::Output->set(
        'Composite',
        outputs=>{
            String=>[
                {conf=>{string=>\$str1}, layout=>[Pattern=>{format=>"[%p] %m"}]},
                {conf=>{string=>\$str2}},
            ],
        });
    My::P1::log_warn("warnmsg");
    My::P1::log_debug("debugmsg");
    is($str1, "[warn] warnmsg\n");
    is($str2, "warnmsg\n");
};

done_testing;
