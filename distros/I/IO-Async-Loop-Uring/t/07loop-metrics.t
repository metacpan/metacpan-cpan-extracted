#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::LoopTests 0.76;
run_tests( 'IO::Async::Loop::Uring', 'metrics' );
