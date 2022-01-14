#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Future::IO::Impl;

use Future::IO;

run_tests 'accept';

done_testing;
