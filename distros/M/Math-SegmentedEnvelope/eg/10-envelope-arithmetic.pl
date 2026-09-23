#!/usr/bin/env perl
# Envelope arithmetic: add, multiply, blend for modulation
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc);

# Carrier: simple ADSR
my $carrier = adsr(0.01, 0.1, 0.8, 0.3);

# Modulator: tremolo LFO (rapid oscillation 0..1)
my $trem = env(
    [[0.5, 1.0, 0.5, 1.0, 0.5, 1.0, 0.5],
     [0.07, 0.07, 0.07, 0.07, 0.07, 0.07],
     [2, -2, 2, -2, 2, -2]],
    is_morph => 1,
    morpher_formula => 'smoothstep',
);

# Multiply: amplitude modulation (carrier * modulator)
my $am = $carrier->multiply($trem, segments => 64);
printf "AM envelope: %d segments, duration %.2fs\n",
    $am->segments, $am->duration;
printf "  range: [%.3f, %.3f]\n", $am->min_value, $am->max_value;

# Add: layer two envelopes
my $layer1 = perc(0.01, 0.2, peak => 0.6);
my $layer2 = perc(0.05, 0.4, peak => 0.4);
my $sum = $layer1->add($layer2, segments => 32);
printf "\nLayered: peak sum = %.3f (%.1f + %.1f)\n",
    $sum->max_value, $layer1->max_value, $layer2->max_value;

# Blend: crossfade between two shapes
my $shape_a = perc(0.01, 0.5, peak => 1.0);
my $shape_b = adsr(0.2, 0.1, 0.8, 0.2, peak => 1.0);

for my $mix (0, 0.25, 0.5, 0.75, 1.0) {
    my $blended = $shape_a->blend($shape_b, $mix, segments => 32);
    printf "  mix=%.2f: at(0.1)=%.3f  at(0.3)=%.3f\n",
        $mix, $blended->at(0.1), $blended->at(0.3);
}
