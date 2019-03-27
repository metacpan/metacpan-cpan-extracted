#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Layout ();

use vars '$str';
use Log::ger::Output 'String', string => \$str, append_newline=>0;

package My::P0;
use Log::ger;

sub x {
    log_warn("warnmsg");
}

sub x2 {
    log_warn("warnmsg\nwarnmsg2");
}

sub x3 {
    log_warn("warnmsg\nwarnmsg2\n");
}

package main;

subtest "basics" => sub {
    subtest "single line" => sub {
        $str = "";
        Log::ger::Layout->set('Pattern::Multiline', format=>'[%p] %m');
        My::P0::x();
        is($str, '[warn] warnmsg');
    };
    subtest "multiline" => sub {
        $str = "";
        Log::ger::Layout->set('Pattern::Multiline', format=>'[%p] %m');
        My::P0::x2();
        is($str, "[warn] warnmsg\n[warn] warnmsg2");
    };
    subtest "multiline with newline ending" => sub {
        $str = "";
        Log::ger::Layout->set('Pattern::Multiline', format=>'[%p] %m');
        My::P0::x3();
        is($str, "[warn] warnmsg\n[warn] warnmsg2");
    };
};

DONE_TESTING:
done_testing;
