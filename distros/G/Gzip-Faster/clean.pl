#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
my $exampleout = "$Bin/file.gz";
if (-f $exampleout) {
    unlink $exampleout or die "Error deleting $exampleout: $!";
}

