#!/usr/bin/perl -w

use IO::Async::LoopTests 0.24;
run_tests( 'IO::Async::Loop::Epoll::FD', 'signal' );
