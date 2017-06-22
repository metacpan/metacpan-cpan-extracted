#!perl

use strict;
use warnings;
use Test::More 0.98;

package My::P1;
use Log::Any '$log';

sub x {
    $log->warn("warn1");
    $log->debug("debug1");
}

package main;

use vars '$str';
use Log::ger::Output;
Log::ger::Output->set('String', string=>\$str);

use Log::Any::Adapter;
Log::Any::Adapter->set('LogGer');

$str = '';
My::P1::x();
is($str, "warn1\n");

done_testing;
