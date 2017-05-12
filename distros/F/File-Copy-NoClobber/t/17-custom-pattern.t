#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Test::Most;
use Test::Warnings;

use File::Spec::Functions;
use File::Basename qw(basename dirname);

use File::Copy::NoClobber -pattern => " woha! (%06d)";

use t::lib::TestUtils;

my $d1 = testdir;
my $d2 = testdir;

my ($fh1,$fn1) = testfile($d1, SUFFIX => ".txt");

copy $fn1, $d2;

my $dest_file = copy $fn1, $d2;

like $dest_file, qr/\Q woha! (000001).txt/,
    "dest file got the 01 pattern";

done_testing;
