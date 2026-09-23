#!/usr/bin/env perl
# Envelope flags: is_hold, is_fold_over, is_wrap_neg and their effects
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

my $def = [[0, 1, 0.3], [0.5, 0.5], [2, -2]];

# Default: time wraps around when exceeding duration
my $wrap = env($def);
printf "Wrap (default):\n";
printf "  at(0.5) = %.3f  at(1.5) = %.3f  at(2.5) = %.3f\n",
    $wrap->at(0.5), $wrap->at(1.5), $wrap->at(2.5);

# is_hold: clamp to [0, duration]
my $hold = env($def, is_hold => 1);
printf "\nis_hold:\n";
printf "  at(-1)  = %.3f  (clamped to 0)\n", $hold->at(-1);
printf "  at(0.5) = %.3f\n", $hold->at(0.5);
printf "  at(2.0) = %.3f  (clamped to end)\n", $hold->at(2.0);
printf "  at(9.0) = %.3f  (still end)\n", $hold->at(9.0);

# is_fold_over: mirror/ping-pong when exceeding duration
my $fold = env($def, is_fold_over => 1);
printf "\nis_fold_over:\n";
for my $t (0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0) {
    printf "  at(%.2f) = %.3f\n", $t, $fold->at($t);
}

# is_morph: apply smoothing function to curve interpolation
my $no_morph = env($def);
my $morph    = env($def, is_morph => 1);
printf "\nis_morph effect at t=0.25:\n";
printf "  without: %.4f\n", $no_morph->at(0.25);
printf "  with:    %.4f  (smoothed by sin(t*PI/2)^2)\n", $morph->at(0.25);

# Combine flags
my $combo = env($def, is_morph => 1, is_fold_over => 1, is_hold => 0);
printf "\nis_morph + is_fold_over (ping-pong with smoothing):\n";
for my $t (0, 0.5, 1.0, 1.5, 2.0) {
    printf "  at(%.1f) = %.3f\n", $t, $combo->at($t);
}
