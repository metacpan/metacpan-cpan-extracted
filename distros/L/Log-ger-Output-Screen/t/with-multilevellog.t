#!perl

use strict;
use warnings;
use Test::More 0.98;

use Capture::Tiny 'capture';
use Log::ger::Output ();

package My::P1;
use Log::ger::Plugin 'MultilevelLog';
use Log::ger;

sub x {
    log("warn", "warnmsg");
    log("trace", "tracemsg");
}

package main;

subtest "basics" => sub {
    my $str = "";
    Log::ger::Output->set('Screen');
    my ($stdout, $stderr, $exit) = capture { My::P1::x() };
    is($stderr, "warnmsg\n");
    is($stdout, "");

    # XXX test conf: use_color
    # XXX test conf: formatter
    # XXX test conf: append_newline
};

done_testing;
