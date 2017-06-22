#!perl

use strict;
use warnings;
use Test::More 0.98;

package My::P1;
use Log::ger;

package main;

use vars '$str';
use Log::Any::Adapter;
Log::Any::Adapter->set('Callback', logging_cb => sub { $str .= $_[2] });

use Log::ger::Output;
Log::ger::Output->set('LogAny');

$str = '';
My::P1::log_warn("warn1");
My::P1::log_debug("debug");
is($str, "warn1");

done_testing;
