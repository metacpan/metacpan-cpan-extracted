#!/usr/bin/perl

BEGIN { $^W = 0 } # disable the warnings that Build has enabled

use IO::Async::LoopTests 0.24;
run_tests( 'IO::Async::Loop::POE', 'child' );
