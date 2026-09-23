#!/usr/bin/env perl
# PWM LED fading: envelope as brightness duty cycle for embedded systems
# Simulates driving an LED via software PWM using envelope curves
#
# In real embedded use, you'd write the duty cycle to a timer register
# or sysfs PWM interface at each tick.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env perc adsr spline);

my $pwm_freq = 1000;   # PWM frequency (Hz)
my $update_hz = 50;     # how often we update the duty cycle
my $duration = 3.0;     # pattern duration

# LED patterns as envelopes (output: 0.0 = off, 1.0 = full brightness)

my %patterns = (
    # Breathing: slow sinusoidal fade in/out
    breathing => env(
        [[0, 1, 0], [1.5, 1.5], [2, -2]],
        is_morph => 1,
        morpher_formula => 'smoothstep',
        is_fold_over => 1,
    ),

    # Heartbeat: double pulse
    heartbeat => env(
        [[0, 0.8, 0.1, 1.0, 0, 0], [0.1, 0.05, 0.08, 0.15, 0.62], [-3, 2, -3, -2, 1]],
        is_fold_over => 1,
    ),

    # Candle flicker: random-ish via spline
    candle => spline(
        [0, 0.1, 0.15, 0.3, 0.35, 0.5, 0.55, 0.7, 0.8, 1.0],
        [0.6, 0.9, 0.4, 0.8, 0.5, 0.95, 0.3, 0.7, 0.85, 0.6],
        is_fold_over => 1,
    ),

    # Alert: fast blink
    alert => env(
        [[0, 1, 0], [0.05, 0.15], [1, 1]],
        is_fold_over => 1,
    ),

    # Fade-in and hold
    fade_in => env(
        [[0, 1], [1.0], [3]],
        is_morph => 1,
        morpher_formula => 'cubic_out',
        is_hold => 1,
    ),

    # Sunrise: gamma-corrected slow ramp
    sunrise => env(
        [[0, 1], [3.0], [1]],
        is_hold => 1,
    )->map_levels(sub { $_[0] ** 2.2 }),  # gamma correction for perceived linearity
);

# Simulate each pattern
for my $name (sort keys %patterns) {
    my $e = $patterns{$name};
    my $s = $e->static;
    my $dur = $e->duration > $duration ? $duration : $e->duration;
    $dur = $duration if $e->is_fold_over;

    printf "\n=== %s (%.1fs) ===\n", $name, $dur;

    my $steps = int($dur * $update_hz);
    for my $i (0 .. $steps - 1) {
        next if $i % 3 != 0;  # print every 3rd step
        my $t = $i / $update_hz;
        my $brightness = $s->($t);
        $brightness = 0 if $brightness < 0;
        $brightness = 1 if $brightness > 1;

        my $duty = int($brightness * 100 + 0.5);
        my $pwm_ticks = int($brightness * $pwm_freq + 0.5);

        # ASCII visualization
        my $bar_len = int($brightness * 30 + 0.5);
        my $bar = '*' x $bar_len . '.' x (30 - $bar_len);

        printf "  t=%4.2f  duty=%3d%%  |%s|", $t, $duty, $bar;

        # Simulated sysfs write (for real embedded use)
        # open my $fh, '>', "/sys/class/pwm/pwmchip0/pwm0/duty_cycle";
        # print $fh $pwm_ticks; close $fh;
        printf "  # echo %d > duty_cycle\n", $pwm_ticks;
    }
}

# Generate C header with lookup table for microcontroller firmware
print "\n=== C lookup table (breathing pattern, 256 entries) ===\n";
my @lut = $patterns{breathing}->table(256);
print "const uint8_t breathing_lut[256] = {\n    ";
for my $i (0 .. 255) {
    my $v = int($lut[$i] * 255 + 0.5);
    $v = 0 if $v < 0;
    $v = 255 if $v > 255;
    printf "%3d", $v;
    print ", " if $i < 255;
    print "\n    " if $i % 16 == 15 && $i < 255;
}
print "\n};\n";
