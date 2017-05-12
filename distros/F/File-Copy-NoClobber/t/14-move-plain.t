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

# on win32 the file cannot be moved while open, so we clean up
# manually
my ($fh1,$fn1) = testfile($d1, UNLINK => 0);
print $fh1 "some content\n";
close $fh1;

move( $fn1, $d2 ) or die "Move failed: $!";

ok !-e $fn1, "after move, source is gone";
ok -s catfile($d2, basename $fn1), "and target exists and has size";

unlink catfile($d2, basename $fn1);

done_testing;
