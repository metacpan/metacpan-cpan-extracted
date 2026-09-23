#!/usr/bin/env perl
# All 26 predefined easing curves compared
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env morpher_formulas);

my @names = morpher_formulas();
my $def = [[0, 1], [1], [1]];

printf "%-16s  %s\n", 'Easing', join('', map { sprintf '%6.1f', $_ / 10 } 0..10);
printf "%-16s  %s\n", '-' x 16, '-' x 66;

for my $name (sort @names) {
    my $e = env($def, morpher_formula => $name);
    printf "%-16s ", $name;
    for my $i (0 .. 10) {
        printf " %5.3f", $e->at($i / 10);
    }
    print "\n";
}

# Visual comparison of key easing families
print "\n";
for my $family (['quad', 'Quadratic'], ['cubic', 'Cubic'], ['circ', 'Circular'],
                ['back', 'Back (overshoot)'], ['elastic', 'Elastic (spring)'],
                ['bounce', 'Bounce']) {
    my ($prefix, $label) = @$family;
    printf "=== %s ===\n", $label;
    for my $suffix ('in', 'out', 'inout') {
        my $name = "${prefix}_${suffix}";
        my $e = env($def, morpher_formula => $name);
        printf "  %-14s  ", $name;
        for my $i (0 .. 40) {
            my $v = $e->at($i / 40);
            my $bar = int($v * 20 + 0.5);
            $bar = 0 if $bar < 0;
            $bar = 20 if $bar > 20;
            print $i % 10 == 0 ? '|' : ($bar == int(0.5 * 20 + 0.5) ? '.' : ' ');
        }
        printf "  %.3f\n", $e->at(0.5);
    }
    print "\n";
}
