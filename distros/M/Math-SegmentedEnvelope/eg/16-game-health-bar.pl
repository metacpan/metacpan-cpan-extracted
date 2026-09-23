#!/usr/bin/env perl
# Game UI: animated health bar with damage flash, regeneration, and smooth transitions
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env perc spline);

# Health bar width
my $bar_width = 50;

# Damage flash: brief white flash then fade
my $flash = perc(0.01, 0.15, peak => 1.0);

# Smooth health transition (spline for natural easing)
sub health_transition {
    my ($from, $to, $duration) = @_;
    $duration //= 0.5;
    return spline([0, $duration], [$from, $to], resolution => 4);
}

# Regeneration pulse: subtle glow oscillation
my $regen_glow = env(
    [[0.0, 0.3, 0.0], [0.5, 0.5], [2, -2]],
    is_morph => 1,
    morpher_formula => 'smoothstep',
    is_fold_over => 1,
);

# Simulate a gameplay sequence
my @events = (
    { time => 0.0, type => 'set',    hp => 100 },
    { time => 0.5, type => 'damage', amount => 30 },
    { time => 2.0, type => 'damage', amount => 25 },
    { time => 3.0, type => 'heal',   amount => 15 },
    { time => 4.0, type => 'damage', amount => 50 },
    { time => 5.0, type => 'regen',  rate => 10 },  # 10 hp/sec for 2s
);

my $max_hp = 100;
my $hp = 100;
my $fps = 20;
my $total_time = 7.0;

# Active animations
my ($health_env, $health_start_t);
my ($flash_env, $flash_start_t);
my $regen_active = 0;
my $regen_start;

my $event_idx = 0;

for my $frame (0 .. int($total_time * $fps)) {
    my $t = $frame / $fps;

    # Process events
    while ($event_idx < @events && $events[$event_idx]{time} <= $t) {
        my $ev = $events[$event_idx++];
        if ($ev->{type} eq 'set') {
            $hp = $ev->{hp};
        } elsif ($ev->{type} eq 'damage') {
            my $new_hp = $hp - $ev->{amount};
            $new_hp = 0 if $new_hp < 0;
            $health_env = health_transition($hp, $new_hp, 0.3);
            $health_start_t = $t;
            $flash_env = $flash;
            $flash_start_t = $t;
            $hp = $new_hp;
            $regen_active = 0;
        } elsif ($ev->{type} eq 'heal') {
            my $new_hp = $hp + $ev->{amount};
            $new_hp = $max_hp if $new_hp > $max_hp;
            $health_env = health_transition($hp, $new_hp, 0.4);
            $health_start_t = $t;
            $hp = $new_hp;
        } elsif ($ev->{type} eq 'regen') {
            $regen_active = 1;
            $regen_start = $t;
        }
    }

    # Calculate display HP
    my $display_hp = $hp;
    if ($health_env && $t - $health_start_t < $health_env->duration) {
        $display_hp = $health_env->at($t - $health_start_t);
    }

    # Regen
    if ($regen_active && $t > $regen_start) {
        my $elapsed = $t - $regen_start;
        if ($elapsed < 2.0) {
            $hp += 10 / $fps;
            $hp = $max_hp if $hp > $max_hp;
            $display_hp = $hp;
        } else {
            $regen_active = 0;
        }
    }

    # Flash intensity
    my $flash_val = 0;
    if ($flash_env && $t - $flash_start_t < $flash_env->duration) {
        $flash_val = $flash_env->at($t - $flash_start_t);
    }

    # Regen glow
    my $glow = 0;
    if ($regen_active) {
        $glow = $regen_glow->at($t - $regen_start);
    }

    # Render bar
    my $filled = int($display_hp / $max_hp * $bar_width + 0.5);
    $filled = 0 if $filled < 0;
    $filled = $bar_width if $filled > $bar_width;

    my $color = $display_hp > 60 ? 'G' : ($display_hp > 25 ? 'Y' : 'R');
    $color = 'W' if $flash_val > 0.3;
    $color = 'g' if $glow > 0.15;

    printf "%5.2fs [%s] HP:%3d%% %s%s%s\n",
        $t, $color,
        int($display_hp + 0.5),
        '#' x $filled,
        '.' x ($bar_width - $filled),
        $regen_active ? ' +regen' : '';
}
