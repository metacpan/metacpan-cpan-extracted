#!/usr/bin/perl

use v5.20;
use warnings;

use IO::Async::LoopTests 0.24;
run_tests( 'IO::Async::Loop::EV', 'control' );
