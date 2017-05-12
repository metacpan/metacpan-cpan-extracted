#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Test::Most;
use Test::Warnings;
use Test::Warn;

use File::Spec::Functions;
use File::Basename qw(basename dirname);

use File::Copy::NoClobber -warn => 1;

use t::lib::TestUtils;

my $d1 = testdir;
my $d2 = testdir;

my ($fh1,$fn1) = testfile($d1, SUFFIX => ".txt");

warning_is { copy $fn1, $d2 } undef,
    "no warning if name not changed";

warning_like { copy $fn1, $d2 }
    qr/Destination changed to/,
    "warns if filename is changed";

done_testing;
