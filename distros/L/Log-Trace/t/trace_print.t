#!/usr/local/bin/perl -w
# $Id: trace_print.t,v 1.3 2004/11/23 14:07:32 simonf Exp $
use strict;
print "1..2\n";

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require Log::Trace;

import Log::Trace 'print';
TRACE("ok 1 (Log::Trace $Log::Trace::VERSION loaded)");

import Log::Trace print => \*STDOUT;
TRACE('ok 2 (print => STDOUT)');

import Log::Trace print => {Level => 1};
TRACE({Level => 999}, "not ok 3 (this shouldn't cause the test to fail)");

sub TRACE {}
