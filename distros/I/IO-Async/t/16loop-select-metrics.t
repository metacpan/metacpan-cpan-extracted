#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use IO::Async::LoopTests;
run_tests( 'IO::Async::Loop::Select', 'metrics' );
