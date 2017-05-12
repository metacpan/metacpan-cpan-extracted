#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;
use Test::Warnings;

use File::Copy::NoClobber;
use t::lib::TestUtils;

my($fh,$fn) = testfile;

my $nonsense_dir = "/foo/bar/baz/" . rand;

throws_ok { copy $fn, $nonsense_dir}
    qr/Invalid destination/,
    "illegal copy throws as expceted";

done_testing;
