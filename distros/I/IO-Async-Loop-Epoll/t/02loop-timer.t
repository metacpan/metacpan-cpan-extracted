#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::LoopTests 0.24;
run_tests( 'IO::Async::Loop::Epoll', 'timer' );
