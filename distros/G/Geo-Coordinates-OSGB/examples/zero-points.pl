#! /usr/bin/perl -w

# Toby Thurston -- 07 Oct 2015 
# Find all the 000 000 grid references that are on a map

use strict;
use Geo::Coordinates::OSGB::Grid "format_grid_map";

my @out = ();

print 'A: Landranger   B: Explorer  C: One-inch', "\n";

for my $n (0 .. 12) {
    for my $e (0 .. 7) {
        my ($sq, undef, undef, @sheets) = format_grid_map($e*100000, $n*100000, {series => 'ABC'});
        next unless @sheets;
        push @out, "$sq 000 000 is on @sheets\n";
    }
}

print sort @out;
