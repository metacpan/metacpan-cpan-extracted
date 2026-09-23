#!/usr/bin/env perl
# LFO wavetable generation for modulation
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Sine-like LFO: 0 -> 1 -> 0 -> -1 -> 0
my $sine_lfo = env(
    [[0, 1, 0, -1, 0],
     [0.25, 0.25, 0.25, 0.25],
     [2, -2, 2, -2]],
    is_morph => 1,
);

# Triangle LFO: linear segments
my $tri_lfo = env(
    [[0, 1, 0, -1, 0],
     [0.25, 0.25, 0.25, 0.25],
     [1, 1, 1, 1]],
);

# Saw LFO: ramp up, instant drop
my $saw_lfo = env(
    [[-1, 1, -1], [0.99, 0.01], [1, 1]],
);

# Generate wavetables (one cycle, 256 samples)
my $size = 256;

print "# Sine-like LFO wavetable ($size samples)\n";
my @sine = $sine_lfo->table($size);
print_table(\@sine);

print "\n# Triangle LFO wavetable\n";
my @tri = $tri_lfo->table($size);
print_table(\@tri);

print "\n# Sawtooth LFO wavetable\n";
my @saw = $saw_lfo->table($size);
print_table(\@saw);

# Multi-cycle table (4 cycles in 1024 samples, for use as a buffer)
my @multi = $sine_lfo->table(1024, 4);
printf "\n# Multi-cycle: %d samples, 4 cycles\n", scalar @multi;
printf "  first cycle peak at sample ~%d: %.4f\n", 64, $multi[64];
printf "  third cycle peak at sample ~%d: %.4f\n", 576, $multi[576];

sub print_table {
    my ($t) = @_;
    for my $i (0 .. $#$t) {
        printf "%4d: %+.6f", $i, $t->[$i];
        # ASCII visualization
        my $bar = int(($t->[$i] + 1) / 2 * 40);
        $bar = 0 if $bar < 0;
        $bar = 40 if $bar > 40;
        print "  |" . (' ' x $bar) . '*' . (' ' x (40 - $bar)) . '|';
        print "\n";
        last if $i > 15;  # truncate output
    }
    printf "  ... (%d more samples)\n", scalar(@$t) - 16 if @$t > 16;
}
