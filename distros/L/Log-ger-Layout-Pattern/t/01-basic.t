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

package main;

subtest "placeholder" => sub {
    subtest '%c' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%c');
        My::P0::x();
        is($str, 'My::P0');
    };
    subtest '%C' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%C');
        My::P0::x();
        is($str, 'main');
    };
    subtest '%d' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%d');
        My::P0::x();
        like($str, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/);
        # XXX test actual time
    };
    subtest '%D' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%D');
        My::P0::x();
        like($str, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/);
        # XXX test actual time
    };
    subtest '%F' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%F');
        My::P0::x();
        ok 1;
        #is($str, 't/01-basic.t');
        # XXX test actual path
    };
    subtest '%H' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%H');
        My::P0::x();
        is($str, Sys::Hostname::hostname());
    };
    subtest '%l' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%l');
        My::P0::x();
        like($str, qr/\AMy::P0::x \(.+?:16\)\z/);
        # XXX test file name
    };
    subtest '%L' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%L');
        My::P0::x();
        is($str, '16');
    };
    subtest '%m' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%m');
        My::P0::x();
        is($str, 'warnmsg');
    };
    subtest '%n' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%n');
        My::P0::x();
        is($str, "\n");
    };
    subtest '%p' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%p');
        My::P0::x();
        is($str, "warn");
    };
    subtest '%P' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%P');
        My::P0::x();
        is($str, $$);
    };
    subtest '%r' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%r');
        My::P0::x();
        ok 1;
        # XXX test actual time offset
    };
    subtest '%R' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%R');
        My::P0::x();
        ok 1;
        # XXX test actual time offset
    };
    subtest '%T' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%T');
        My::P0::x();
        like($str, qr/\A\w+::[^\n]+\n\w+::/);
        # XXX test actual stack trace
    };
    subtest '%%' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'%%');
        My::P0::x();
        is($str, '%');
    };

    subtest 'basics' => sub {
        $str = "";
        Log::ger::Layout->set('Pattern', format=>'[%d %p] %m%n');
        My::P0::x();
        like($str, qr/\A\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} warn\] warnmsg\n\z/);
    };
};

DONE_TESTING:
done_testing;
