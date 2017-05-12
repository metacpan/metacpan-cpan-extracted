#!/usr/bin/perl -w
my $file = shift || die "$0 needs a file argument";
open(STDOUT, ">", $file) || die "Could not create $file: $!\n";
$| = 1;
print while <>;
