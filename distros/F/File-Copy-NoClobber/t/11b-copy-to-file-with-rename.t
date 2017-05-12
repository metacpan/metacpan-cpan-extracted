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

my ($fh1,$fn1) = testfile($d1, SUFFIX => ".txt");
my $bn1 = basename $fn1;

print $fh1 "Some content to go in the file\n";
my $s1 = -s $fn1;

my $dest1 = copy $fn1, $d2;
copy $fn1, catfile($d2, "name2.txt");

print $fh1 "More content to make the files different\n";
my $s2 = -s $fn1;

my $new_dest = catfile( $d2, "name2.txt" );
ok -s $new_dest, "as expected the dest exist";

my $final_dest_file = copy $fn1, $new_dest;

like $final_dest_file, qr/name2 \Q (01).txt/x,
    "dest file got the 01 pattern of given filename";

ok -s $final_dest_file, "new dest file has content";

isnt -s $dest1, -s $final_dest_file,
    "file sizes are as expected";

done_testing;
