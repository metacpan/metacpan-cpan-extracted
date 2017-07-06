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
    log_debug("debug");
}

package My::P1; # use Log::ger before Log::ger::Format
use Log::ger::Format;
BEGIN { Log::ger::Format->set_for_current_package('Block') }
use Log::ger;

sub x {
    log_warn { "wa" . "rn" };
    log_debug { "de" . "bug" };
}

package My::P2; # use Log::ger after use Log::ger::Format
use Log::ger;
use Log::ger::Format;
BEGIN { Log::ger::Format->set_for_current_package('Block') }

sub x {
    log_warn { "wa" . "rn" };
    log_debug { "de" . "bug" };
}

package main;

$str = "";
My::P0::x();
is($str, "warn\n");

$str = "";
My::P1::x();
is($str, "warn\n");

$str = "";
My::P2::x();
is($str, "warn\n");

DONE_TESTING:
done_testing;
