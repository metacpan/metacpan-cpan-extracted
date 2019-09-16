#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2019 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use autodie;

use v5.10;

use Carp;

use Test2::V0;
use Test2::Require::Module 'Parallel::WorkUnit' => 2.181850;

use Fcntl;
use File::ByLine;

ok(
    lives { parallel_dolines { return; } "t/data/zero.txt", 1 },
    "Successfuly handles zero length files"
);

ok(
    lives { parallel_dolines { return; } "t/data/zero.txt", 10 },
    "Successfuly handles zero length files (with multi threads)"
);

done_testing;

