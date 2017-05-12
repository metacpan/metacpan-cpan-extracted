#!/usr/local/bin/perl -w
use strict;
use PDL;

sub pm {
    my ($f, $g) = @_;
    
    my $h = (pdl $f) x (pdl $g);

    print  "$h\n";
}

my $f = [[1,2],[3,4]];
pm($f, $f);

