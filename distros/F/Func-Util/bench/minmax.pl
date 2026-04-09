#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use List::Util ();
use Func::Util qw(min2 max2);

print "=" x 60, "\n";
print "min2/max2 - Two-Value Min/Max Benchmark\n";
print "=" x 60, "\n\n";

my ($a, $b) = (42, 99);

print "=== min2 ===\n";
cmpthese(-2, {
    'util::min2'      => sub { min2($a, $b) },
    'List::Util::min' => sub { List::Util::min($a, $b) },
    'ternary'         => sub { $a < $b ? $a : $b },
});

print "\n=== max2 ===\n";
cmpthese(-2, {
    'util::max2'      => sub { max2($a, $b) },
    'List::Util::max' => sub { List::Util::max($a, $b) },
    'ternary'         => sub { $a > $b ? $a : $b },
});

print "\n=== min2 (equal values) ===\n";
cmpthese(-2, {
    'util::min2'      => sub { min2(50, 50) },
    'List::Util::min' => sub { List::Util::min(50, 50) },
});

print "\nDONE\n";
