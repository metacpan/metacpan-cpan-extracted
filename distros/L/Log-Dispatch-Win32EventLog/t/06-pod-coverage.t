#!/usr/bin/perl

use strict;
use Test::More tests => 1;

SKIP: {
    skip( 'Test::Pod::Coverage not installed on this system', 1 )
        unless do {
            eval "use Test::Pod::Coverage";
            $@ ? 0 : 1;
        };
    pod_coverage_ok( 'Log::Dispatch::Win32EventLog', 'Log-Dispatch-Win32EventLog POD coverage is go!' );
}
