#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Future::IO::Impl;

use Future::IO;
use Future::IO::Impl::Uring;

alarm 5;
run_tests 'sleep';

done_testing;
