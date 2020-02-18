#!perl

use strict;
use warnings;
use Test::More 0.98;

use vars '$str';
use Log::ger::Output 'String', string => \$str;

package My::P0;
use Log::ger;

sub x {
    log_warn("warn");
}

package My::P1;
use Log::ger::Format;
BEGIN { Log::ger::Format->set_for_current_package('Join') }
use Log::ger;

sub x {
    log_warn("arg1", "arg2", " arg3");
}

package My::P2;
use Log::ger::Format;
BEGIN { Log::ger::Format->set_for_current_package('Join', with=>"; ") }
use Log::ger;

sub x {
    log_warn("arg1", "arg2", " arg3");
}

package main;

$str = "";
My::P0::x();
is($str, "warn\n");

$str = "";
My::P1::x();
is($str, "arg1arg2 arg3\n");

$str = "";
My::P2::x();
is($str, "arg1; arg2;  arg3\n");

DONE_TESTING:
done_testing;
