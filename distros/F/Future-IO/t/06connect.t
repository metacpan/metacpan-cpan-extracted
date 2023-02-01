#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Future::IO::Impl;

use Future::IO;

run_tests 'connect';

done_testing;
