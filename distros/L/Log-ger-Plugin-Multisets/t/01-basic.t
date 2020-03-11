#!perl

use strict;
use warnings;
use Test::More 0.98;

use vars '$str';
use Log::ger::Output 'String', string => \$str;

package My::P1;
use Log::ger::Plugin Multisets => (
    logger_sub_prefixes => {
        log_    => {category => 'error'},
        access_ => {category => 'access'},
    },
    level_checker_sub_prefixes => {
        log_is    => {category => 'error'},
        access_is => {category => 'access'},
    },
);
use Log::ger;

sub x {
    log_warn    ("error-warn");
    log_debug   ("error-debug");
    access_warn ("access-warn");
    access_debug("access-debug");
}

package main;

$str = "";
My::P1::x();
is($str, "error-warn\naccess-warn\n");

DONE_TESTING:
done_testing;
