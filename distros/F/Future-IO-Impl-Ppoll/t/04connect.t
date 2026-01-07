#!/usr/bin/perl

use v5.20;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl;

use Future::IO;
use Future::IO::Impl::Ppoll;

run_tests 'connect';

done_testing;
