#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl 0.15;

use Future::IO 0.17;
use Future::IO::Impl::UV;

run_tests 'read';
run_tests 'sysread';

done_testing;
