#!/usr/bin/env perl
use 5.020;
use warnings;
use strict;
use Getopt::Long qw/:config gnu_getopt/;

my $filename = $ARGV[0] // die "Need filename arg";

open my $fh, '<', $filename
    or die "Cannot open $filename: $!";
my $id = 0;
while ( my $line = <$fh> ) {
    if ( $line =~ /id: [0-9]+/ ) {
        $line =~ s/id: [0-9]+/id: $id/;
        ++$id;
    }
    print $line;
}

