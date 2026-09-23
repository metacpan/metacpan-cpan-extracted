#!/usr/bin/env perl
# Envelope diff: compare morphers visually side-by-side
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

my $def = [[0, 1], [1], [1]];
my $width = 50;
my $height = 12;

# Compare pairs
my @pairs = (
    ['linear',     'smoothstep'],
    ['quad_out',   'cubic_out'],
    ['cubic_out',  'bounce_out'],
    ['back_out',   'elastic_out'],
    ['circ_in',    'exp_in'],
    ['smoothstep', 'smootherstep'],
);

for my $pair (@pairs) {
    my ($na, $nb) = @$pair;
    my $ea = env($def, morpher_formula => $na);
    my $eb = env($def, morpher_formula => $nb);

    my @va = $ea->table($width);
    my @vb = $eb->table($width);

    printf "\n  %-16s vs  %-16s\n", $na, $nb;

    # Overlay plot: A='*', B='o', both='@'
    for my $y (reverse 0 .. $height - 1) {
        my $level = $y / ($height - 1);
        printf "%5.2f |", $level;
        for my $x (0 .. $width - 1) {
            my $ya = int($va[$x] * ($height - 1) + 0.5);
            my $yb = int($vb[$x] * ($height - 1) + 0.5);
            my $is_a = ($ya == $y);
            my $is_b = ($yb == $y);
            if ($is_a && $is_b) { print '@' }
            elsif ($is_a)       { print '*' }
            elsif ($is_b)       { print 'o' }
            else                { print ' ' }
        }
        print "|\n";
    }
    printf "      +%s+\n", '-' x $width;

    # Numerical diff at key points
    printf "  %6s", '';
    for my $t (0.1, 0.25, 0.5, 0.75, 0.9) {
        printf "  t=%.2f", $t;
    }
    print "\n";
    for my $row ([$na, $ea], [$nb, $eb]) {
        printf "  %-6s", $row->[0];
        for my $t (0.1, 0.25, 0.5, 0.75, 0.9) {
            printf "  %5.3f", $row->[1]->at($t);
        }
        print "\n";
    }
    printf "  %-6s", 'diff';
    for my $t (0.1, 0.25, 0.5, 0.75, 0.9) {
        printf "  %+5.3f", $ea->at($t) - $eb->at($t);
    }
    print "\n";
}

# Show derivative comparison for selected pair
print "\n=== Rate of change: cubic_out vs bounce_out ===\n";
my $da = env($def, morpher_formula => 'cubic_out')->resample(32)->derivative;
my $db = env($def, morpher_formula => 'bounce_out')->resample(32)->derivative;
printf "  %-12s peak_slope=%.2f\n", 'cubic_out', $da->max_value;
printf "  %-12s peak_slope=%.2f\n", 'bounce_out', $db->max_value;
