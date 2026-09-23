#!/usr/bin/env perl
# Animation easing curves: position/opacity/scale over time
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env);

# Slide-in animation: element moves from x=100 to x=0 with bounce
my $slide = env(
    [[100, -5, 2, 0],    # overshoot then settle
     [0.3, 0.1, 0.1],
     [-3, 2, -2]],
    is_morph => 1,
    morpher_formula => 'smootherstep',
    is_hold => 1,         # clamp at final position
);

# Fade-in: opacity 0 -> 1
my $fade = env(
    [[0, 1], [0.5], [2]],
    is_morph => 1,
    morpher_formula => 'cubic_out',
    is_hold => 1,
);

# Scale pulse: 1.0 -> 1.2 -> 1.0 (button press feedback)
my $pulse = env(
    [[1.0, 1.2, 1.0], [0.1, 0.15], [-2, 2]],
    is_morph => 1,
    morpher_formula => 'smoothstep',
    is_hold => 1,
);

# Simulate 60fps animation loop
my $fps = 60;
my $dur = $slide->duration;
my $frames = int($dur * $fps);

my $s_slide = $slide->static;
my $s_fade  = $fade->static;
my $s_pulse = $pulse->static;

printf "%-6s  %8s  %8s  %8s\n", 'time', 'x', 'opacity', 'scale';
printf "%-6s  %8s  %8s  %8s\n", '----', '-------', '-------', '-----';

for my $f (0 .. $frames) {
    my $t = $f / $fps;
    next unless $f % 3 == 0;  # print every 3rd frame
    printf "%5.2fs  %8.2f  %8.3f  %8.3f\n",
        $t, $s_slide->($t), $s_fade->($t), $s_pulse->($t);
}

# Show which segment is active at each keyframe
print "\nSlide keyframes:\n";
for my $t (0, 0.15, 0.3, 0.4, 0.5) {
    printf "  t=%.2f: segment %d, x=%.2f\n", $t, $slide->segment_at($t), $slide->at($t);
}
