#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

use vars '$str';
use Log::ger::Output 'String', string => \$str;

package My::P0;
use Log::ger;

package My::P1;
use Log::ger::OptAway;
use Log::ger;

package main;

$str = "";
My::P0::log_warn("warn");
My::P0::log_debug("debug");
is($str, "warn\n");

$str = "";
My::P1::log_warn("warn");
My::P1::log_debug("debug");
is($str, "warn\n");

Log::ger::Util::reset_plugins('after_install_log_routine');
Log::ger::Util::set_level(5);

# XXX why is P0's also optimized away?
$str = "";
My::P0::log_warn("warn");
My::P0::log_debug("debug");
is($str, "warn\n");

$str = "";
My::P1::log_warn("warn");
My::P1::log_debug("debug");
is($str, "warn\n");

DONE_TESTING:
done_testing;
