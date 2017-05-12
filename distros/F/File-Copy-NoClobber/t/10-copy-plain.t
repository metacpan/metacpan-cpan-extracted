#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;
use Test::Warnings;

use File::Spec::Functions;
use File::Basename qw(basename dirname);

use File::Copy::NoClobber;

use t::lib::TestUtils;

my $d1 = testdir;
my $d2 = testdir;

my ($fh1,$fn1) = testfile($d1);

print $fh1 "some content\n";

ok !-e catfile( $d2, basename $fn1 ),
    "at first the destination file does not exist";

copy $fn1, $d2;

ok -s catfile( $d2, basename $fn1 ),
    "but after copy destination file exists and has size";

ok -s $fn1, "and source file still exists in source directory";

done_testing;
