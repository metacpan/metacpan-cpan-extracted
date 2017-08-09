#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

use vars '$str';
use Log::ger::Output 'String', string => \$str;

package My::P0;
use Log::ger;

package My::P0b;
use Log::ger;

package My::P1;
use Log::ger::Plugin;
BEGIN { Log::ger::Plugin->set_for_current_package('OptAway') }
use Log::ger;

package main;

$str = "";
My::P0::log_warn("warn");
My::P0::log_debug("debug1");
if (My::P0::log_is_debug()) { My::P0::log_debug("debug2") }
is($str, "warn\n");

$str = "";
My::P1::log_warn("warn");
My::P1::log_debug("debug1");
if (My::P1::log_is_debug()) { My::P1::log_debug("debug2") }
is($str, "warn\n");

Log::ger::Util::set_level(50);

# XXX why P0 also affected by the plugin? it seems all packages are affected
# globally, so we can't do set_for_current_package()?

$str = "";
My::P0::log_warn("warn");
My::P0::log_debug("debug1");
if (My::P0::log_is_debug()) { My::P0::log_debug("debug2") }
is($str, "warn\n");
#use Data::Dmp; dd \%My::P1::;

$str = "";
My::P1::log_warn("warn");
My::P1::log_debug("debug1");
if (My::P1::log_is_debug()) { My::P1::log_debug("debug2") }
is($str, "warn\n");

DONE_TESTING:
done_testing;
