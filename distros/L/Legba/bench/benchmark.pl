#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese timethese :hireswallclock);
use blib;

use Legba qw/bench_slot/;

# Warm up
bench_slot("warmup");
my $x = bench_slot();

print "=== Legba Slot Benchmark ===\n\n";

# Test 1: Getter performance
print "--- Getter Performance (10M iterations) ---\n";
my $result = timethese(10_000_000, {
    'slot_getter' => sub { my $v = bench_slot(); },
});
print "\n";

# Test 2: Setter performance  
print "--- Setter Performance (10M iterations) ---\n";
$result = timethese(10_000_000, {
    'slot_setter' => sub { bench_slot(42); },
});
print "\n";

# Test 3: Mixed get/set
print "--- Mixed Get/Set (5M iterations each) ---\n";
$result = timethese(5_000_000, {
    'get_then_set' => sub { 
        my $v = bench_slot();
        bench_slot($v + 1);
    },
});
print "\n";

# Test 4: Compare to hash access
print "--- Comparison: Slot vs Hash vs Scalar (10M iterations) ---\n";
my %hash = (bench => 0);
my $scalar = 0;
bench_slot(0);

cmpthese(10_000_000, {
    'legba_get' => sub { my $v = bench_slot(); },
    'hash_get'  => sub { my $v = $hash{bench}; },
    'scalar_get'=> sub { my $v = $scalar; },
});
print "\n";

cmpthese(10_000_000, {
    'legba_set' => sub { bench_slot(42); },
    'hash_set'  => sub { $hash{bench} = 42; },
    'scalar_set'=> sub { $scalar = 42; },
});
print "\n";

print "=== Benchmark Complete ===\n";
