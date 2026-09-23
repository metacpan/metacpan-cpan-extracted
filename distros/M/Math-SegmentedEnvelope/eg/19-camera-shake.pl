#!/usr/bin/env perl
# Camera shake effect: decaying random displacement for game/film
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env perc);

srand(123);

# Shake intensity envelope: sharp onset, exponential decay
my $intensity = perc(0.01, 0.8, peak => 1.0);

# Frequency envelope: fast shake at start, slower at end
my $freq_env = env([[30, 15, 5], [0.3, 0.5], [-2, -1]], is_hold => 1);

my $fps = 30;
my $dur = $intensity->duration;
my $frames = int($dur * $fps);

my $int_s  = $intensity->static;
my $freq_s = $freq_env->static;

printf "Camera shake: %.2fs at %d fps (%d frames)\n\n", $dur, $fps, $frames;
printf "%-6s  %6s  %6s  %s\n", 'time', 'dx', 'dy', 'visual';
printf "%-6s  %6s  %6s  %s\n", '----', '----', '----', '------';

my $phase_x = rand() * 6.28;
my $phase_y = rand() * 6.28;

for my $f (0 .. $frames) {
    my $t = $f / $fps;
    my $amp = $int_s->($t) * 10;  # max 10 pixel displacement
    my $freq = $freq_s->($t);

    # Perlin-ish: sum of two sine waves at different frequencies
    my $dx = sin($phase_x + $t * $freq * 6.28) * $amp
           + sin($phase_x * 1.7 + $t * $freq * 2.1 * 6.28) * $amp * 0.3;
    my $dy = sin($phase_y + $t * $freq * 6.28) * $amp
           + cos($phase_y * 1.3 + $t * $freq * 1.8 * 6.28) * $amp * 0.3;

    # ASCII visualization
    my $cx = 30 + int($dx + 0.5);
    $cx = 0 if $cx < 0;
    $cx = 60 if $cx > 60;
    my $bar = ' ' x 61;
    substr($bar, 30, 1, '|');
    substr($bar, $cx, 1, $cx == 30 ? '|' : 'X');

    printf "%5.2fs  %+6.1f  %+6.1f  %s\n", $t, $dx, $dy, $bar;
}
