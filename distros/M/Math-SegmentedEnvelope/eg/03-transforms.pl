#!/usr/bin/env perl
# Envelope transformations: scale, offset, stretch, reverse, invert, delay
use strict;
use warnings;
use Math::SegmentedEnvelope qw(perc adsr);

my $e = perc(0.01, 0.3, peak => 1.0);
printf "Original:   dur=%.2f  range=[%.2f, %.2f]\n",
    $e->duration, $e->min_value, $e->max_value;

# Scale levels (amplitude modulation)
my $loud = $e->scale(2.0);
printf "scale(2):   dur=%.2f  range=[%.2f, %.2f]\n",
    $loud->duration, $loud->min_value, $loud->max_value;

# Offset levels (DC offset)
my $shifted = $e->offset(0.5);
printf "offset(.5): dur=%.2f  range=[%.2f, %.2f]\n",
    $shifted->duration, $shifted->min_value, $shifted->max_value;

# Stretch time (tempo change)
my $slow = $e->stretch(3.0);
my $fast = $e->stretch(0.5);
printf "stretch(3): dur=%.2f\n", $slow->duration;
printf "stretch(.5):dur=%.2f\n", $fast->duration;

# Reverse (play backwards)
my $rev = $e->reverse;
printf "reverse:    at(0)=%.2f at(end)=%.2f\n",
    $rev->at(0), $rev->at($rev->duration);

# Invert (1 - level)
my $inv = $e->invert;
printf "invert:     at(0)=%.2f peak=%.2f\n",
    $inv->at(0), $inv->min_value;

# Delay (prepend silence)
my $delayed = $e->delay(0.5);
printf "delay(.5):  dur=%.2f  at(0.25)=%.4f at(0.51)=%.4f\n",
    $delayed->duration, $delayed->at(0.25), $delayed->at(0.51);

# Combine transforms: fade-in ramp
my $ramp = perc(0.01, 0.3)->reverse->stretch(2.0)->offset(0.1);
printf "\nFade-in ramp: dur=%.2f range=[%.2f, %.2f]\n",
    $ramp->duration, $ramp->min_value, $ramp->max_value;
