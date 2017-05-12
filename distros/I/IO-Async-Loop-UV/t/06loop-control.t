#!/usr/bin/perl

use strict;
use warnings;

use UV; # avoid CHECK warning

use IO::Async::LoopTests 0.24;
run_tests( 'IO::Async::Loop::UV', 'control' );
