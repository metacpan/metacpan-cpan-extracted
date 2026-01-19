#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl;

use Future::IO;
use Future::IO::Impl::Glib;

run_tests 'waitpid';

done_testing;
