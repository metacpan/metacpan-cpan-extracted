#!perl

use strict;
use warnings;
use Test::More 0.98;

package My::P1;
use Log::ger::Like::LogAny '$log';

sub x {
    $log->warn("w", "arn1");
    if ($log->is_trace) {
        $log->error("debug1");
    }
}

package My::P2;
use Log::ger::Like::LogAny;

sub x {
    my $log = Log::Any->get_logger;
    $log->warnf("warn%d", 1+1);
    $log->debugf("debug2");
}

package main;

use vars '$str';
use Log::ger::Output;
Log::ger::Output->set('String', string => \$str);

$str = '';
My::P1::x();
My::P2::x();
is($str, "w arn1\nwarn2\n");

done_testing;
