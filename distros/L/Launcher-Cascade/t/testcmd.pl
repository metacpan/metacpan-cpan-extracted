#!perl

my ($filename, $pattern) = @ARGV;
open FH, '>>', $filename or die "Cannot write to $filename: $!";
print FH "$pattern\n";
close FH;
