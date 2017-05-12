#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Test::Most;
use Test::Warnings;

use File::Spec::Functions;
use File::Basename qw(basename dirname);

use File::Copy::NoClobber;

use t::lib::TestUtils;

my $d1 = testdir;
my $d2 = testdir;

my ($fh1,$fn1) = testfile($d1);

print $fh1 "Some content to go in the file\n";

my $df1 = copy $fn1, $d2;
my $df2 = copy $fn1, $d2;

is basename($df1), basename($fn1),
    "first copy preserves source filename";

isnt basename($df2), basename($fn1),
    "second copy has changed it";

like $df2, qr/\Q (01)\E$/,
    "noclobber filename with counter looks right";

my $df3 = copy $fn1, $d2;

like $df3, qr/\Q (02)\E$/,
    "still does";

done_testing;
