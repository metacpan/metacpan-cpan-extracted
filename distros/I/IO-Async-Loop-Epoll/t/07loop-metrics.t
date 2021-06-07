#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::LoopTests 0.76;
run_tests( 'IO::Async::Loop::Epoll', 'metrics' );
