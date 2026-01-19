#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl 0.15;

use Future::IO;

run_tests 'recv';
run_tests 'recvfrom';

done_testing;
