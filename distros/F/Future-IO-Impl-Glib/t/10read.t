#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl 0.15;

use Future::IO 0.17;
use Future::IO::Impl::Glib;

run_tests 'read';
run_tests 'sysread';

done_testing;
