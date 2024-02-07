#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use IO::Async::LoopTests;
plan skip_all => "This OS does not have signals" unless IO::Async::OS->HAVE_SIGNALS;

run_tests( 'IO::Async::Loop::Select', 'signal' );
