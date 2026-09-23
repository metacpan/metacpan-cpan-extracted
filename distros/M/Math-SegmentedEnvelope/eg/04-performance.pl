#!/usr/bin/env perl
# Performance: static evaluator, table generation, JIT backends
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr);
use Time::HiRes qw(time);

my $e = adsr(0.01, 0.1, 0.7, 0.3, is_morph => 1);

# Method 1: at() - full method dispatch per call
my $N = 100_000;
my $t0 = time();
my $sum = 0;
for my $i (0 .. $N-1) {
    $sum += $e->at($i / $N * $e->duration);
}
printf "at() x %dk:     %5.0f ms\n", $N/1000, (time()-$t0)*1000;

# Method 2: static() - captured state, callable as closure
my $s = $e->static;
$t0 = time();
$sum = 0;
for my $i (0 .. $N-1) {
    $sum += $s->($i / $N * $e->duration);
}
printf "static() x %dk: %5.0f ms\n", $N/1000, (time()-$t0)*1000;

# Method 3: table() - bulk generation in C, returns list
$t0 = time();
my @tbl = $e->table($N);
printf "table(%dk):      %5.0f ms\n", $N/1000, (time()-$t0)*1000;

# JIT morpher comparison
print "\nMorpher backends:\n";
for my $formula ('t*t*(3-2*t)', 'sin(t*1.5708)^2', 'exp(-3*(1-t))') {
    my $je = adsr(0.01, 0.1, 0.7, 0.3,
        morpher_formula => $formula);
    $t0 = time();
    my @t = $je->table(1_000_000);
    printf "  %-25s [%s] %5.0f ms\n",
        $formula, $je->morpher_jit_backend, (time()-$t0)*1000;
}

# Predefined morphers (native C, no JIT overhead)
for my $name ('linear', 'smoothstep', 'cubic_inout') {
    my $pe = adsr(0.01, 0.1, 0.7, 0.3,
        morpher_formula => $name);
    $t0 = time();
    my @t = $pe->table(1_000_000);
    printf "  %-25s [predef] %5.0f ms\n", $name, (time()-$t0)*1000;
}
