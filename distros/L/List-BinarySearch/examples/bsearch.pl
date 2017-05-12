#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'once';

use List::BinarySearch qw( binsearch );

my @numbers = ( 32767 .. 65535 );
my $target  = 60000;

my $found_ix = binsearch { $a <=> $b } $target, @numbers;

if ( defined $found_ix ) {
    print "Found $target in range (32767..65535) at index $found_ix.\n";
}
else {
    print "Didn't find $target in range (32767..65535).\n";
}
