#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Test::Future::IO::Impl;

use Future::IO;
use Future::IO::Impl::Glib;

run_tests 'connect';

done_testing;
