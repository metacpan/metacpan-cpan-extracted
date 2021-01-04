#!/usr/bin/env perl
use warnings;
use strict;

if (! @ARGV) {
    print "Usage: ./quote_file_contents.pl filename.ext\n";
    exit;
}

my $f = $ARGV[0];

open my $fh, '<', $f or die $!;

while (<$fh>) {
    chomp;
    print qq{qq{$_},\n};
}
