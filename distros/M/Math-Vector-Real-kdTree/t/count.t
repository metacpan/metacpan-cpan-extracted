#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 40;

use Math::Vector::Real::kdTree;

my $tree = Math::Vector::Real::kdTree->new();
my @is;
for my $i (0..39) {
    push @is, $i;
    $tree->insert(Math::Vector::Real->new($i));
    my @all = sort { $a <=> $b } $tree->ordered_by_proximity;
    is ("@all", "@is", "count indexes - $i");
}
