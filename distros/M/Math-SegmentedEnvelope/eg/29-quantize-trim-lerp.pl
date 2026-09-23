#!/usr/bin/env perl
# New XS methods: quantize, trim, lerp
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr perc);

my $dev = 0.001;

# === quantize: snap levels to N discrete steps ===
print "=== quantize ===\n";
my $e = adsr(0.1, 0.1, 0.7, 0.3);
for my $steps (2, 4, 8, 16) {
    my $q = $e->quantize($steps);
    my @levels = @{$q->def->[0]};
    printf "  steps=%2d: levels = %s\n", $steps,
        join(', ', map { sprintf '%.3f', $_ } @levels);
}

# Quantize preserves durations and curves
my $q4 = $e->quantize(4);
printf "  duration preserved: %.2f == %.2f? %s\n",
    $e->duration, $q4->duration,
    abs($e->duration - $q4->duration) < $dev ? 'YES' : 'NO';

# === trim: extract a time slice ===
print "\n=== trim ===\n";
my $full = adsr(0.1, 0.1, 0.7, 0.5, morpher_formula => 'smoothstep');
printf "  Full: dur=%.2f segs=%d\n", $full->duration, $full->segments;

# Trim attack+decay phase only
my $attack = $full->trim(0, 0.2);
printf "  Attack (0-0.2): dur=%.2f segs=%d at(0)=%.3f at(end)=%.3f\n",
    $attack->duration, $attack->segments,
    $attack->at(0), $attack->at($attack->duration - 0.001);

# Trim sustain phase
my $sustain = $full->trim(0.2, 0.7);
printf "  Sustain (0.2-0.7): dur=%.2f segs=%d\n",
    $sustain->duration, $sustain->segments;

# Custom resolution
my $hires = $full->trim(0, 0.5, segments => 64);
printf "  Hi-res (0-0.5, 64 segs): dur=%.2f segs=%d\n",
    $hires->duration, $hires->segments;

# === lerp: interpolate between two envelopes ===
print "\n=== lerp ===\n";
my $bright = perc(0.01, 0.3, peak => 1.0);
my $soft   = perc(0.01, 0.3, peak => 0.5);

for my $mix (0, 0.25, 0.5, 0.75, 1.0) {
    my $l = $bright->lerp($soft, $mix);
    printf "  mix=%.2f: peak=%.3f\n", $mix, $l->at(0.01);
}

# lerp interpolates durations too
my $fast = perc(0.01, 0.2);
my $slow = perc(0.01, 0.8);
my $mid = $fast->lerp($slow, 0.5);
printf "\n  fast dur=%.2f, slow dur=%.2f, lerp(0.5) dur=%.2f\n",
    $fast->duration, $slow->duration, $mid->duration;

# lerp also interpolates curves
my $sharp = Math::SegmentedEnvelope->new([[0, 1], [1], [4]]);   # steep curve
my $gentle = Math::SegmentedEnvelope->new([[0, 1], [1], [1]]);  # linear
my $between = $sharp->lerp($gentle, 0.5);
my @curves = @{$between->def->[2]};
printf "  sharp curve=4, gentle curve=1, lerp curve=%.1f\n", $curves[0];
