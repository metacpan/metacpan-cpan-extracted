#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl;

use Future::IO;

run_tests 'connect';

done_testing;
