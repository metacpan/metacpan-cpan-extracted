#!/usr/bin/perl

use t::lib::Test tests => 2;

use_ok('Devel::Debug::DBGp');
run_debugger('t/scripts/base.pl');

ok(1); # we survived
