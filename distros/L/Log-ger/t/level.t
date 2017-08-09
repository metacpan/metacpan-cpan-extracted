#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger ();
use Log::ger::Util;

BEGIN {
    %Log::ger::Levels = (
        foo => 10,
        bar => 20,
        baz => 30,
        qux => 40,
    );
}

package My::P1;
use Log::ger;

package main;

subtest "basics" => sub {
    my $str = "";
    require Log::ger::Output;
    Log::ger::Output->set('String', string => \$str);

    My::P1::log_foo("foo");
    My::P1::log_bar("bar");
    My::P1::log_baz("baz");
    My::P1::log_qux("qux");
    is($str, "foo\nbar\nbaz\n");
    {
        $str = "";
        Log::ger::Util::set_level("foo");
        My::P1::log_foo("foo");
        My::P1::log_bar("bar");
        is($str, "foo\n");
    }
};

done_testing;
