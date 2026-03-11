#!/usr/bin/perl
use 5.016;
use strict;
use warnings;

use EBook::Ishmael::CharDet;

my $USAGE = <<"HERE";
Usage: $0 <file>
HERE

my $file = shift @ARGV;
if (not defined $file) {
    die $USAGE;
}

open my $fh, '<', $file or die "Failed to open $file for reading: $!";
binmode $fh;
my $slurp = do { local $/; <$fh> };
close $fh;

my $encoding = chardet($slurp);
if (defined $encoding) {
    say $encoding;
} else {
    die "Could not identify character encoding for $file :-(";
}
