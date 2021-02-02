#!perl

use strict;
use warnings;
use Test::More 0.98;

use Log::ger::Util;

use vars '$str';
use Log::ger::Output 'String', string => \$str;

package My::P1;
use Log::ger::Format 'MultilevelLog';
use Log::ger;

sub x {
    log(30, "warnmsg");
    log(50, "debugmsg");
}

package main;

$str = "";
My::P1::x();
is($str, "warnmsg\n");

done_testing;
