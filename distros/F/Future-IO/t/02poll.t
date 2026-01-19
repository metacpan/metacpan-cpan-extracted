#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl 0.17;

use Future::IO;

# default impl cannot do HUP
run_tests 'poll_no_hup';

done_testing;
