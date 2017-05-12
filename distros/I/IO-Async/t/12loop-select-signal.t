#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::LoopTests;
Test::More::plan skip_all => "This OS does not have signals" unless IO::Async::OS->HAVE_SIGNALS;

run_tests( 'IO::Async::Loop::Select', 'signal' );
