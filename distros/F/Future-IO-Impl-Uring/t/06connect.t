#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Future::IO::Impl;

use Future::IO;
use Future::IO::Impl::Uring;

run_tests 'connect';

done_testing;
