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

my ($fh1,$fn1) = testfile($d1, SUFFIX => ".txt", UNLINK => 0 );
print $fh1 "some content\n";

my $s1 = -s $fn1;

# first copy it so it exists in destination
my $dest1 = catfile( $d2, basename $fn1 );
copy( $fn1, $d2 );

# then move it
print $fh1 "some more content\n";
my $s2 = -s $fn1;

isnt $s1, $s2, "two versions of file have different size";

close $fh1;
my $new_dest = move( $fn1, $d2 );

like $new_dest,
    qr/\Q (01).txt/,
    "destination has counter";

is -s $new_dest, $s2,
    "the new renamed file has same content size as the source";

done_testing;
