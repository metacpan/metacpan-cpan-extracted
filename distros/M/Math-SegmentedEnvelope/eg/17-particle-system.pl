#!/usr/bin/env perl
# Particle system: envelopes control particle lifetime properties
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env perc spline);

srand(42);

# Particle property envelopes (normalized to 0..1 lifetime)
my $alpha = perc(0.05, 0.95, peak => 1.0);          # fade in fast, fade out slow
my $size  = spline([0, 0.1, 0.5, 1.0],              # grow then shrink
                   [0, 1.5, 1.0, 0], resolution => 8);
my $speed = env([[1.0, 0.3, 0.1], [0.3, 0.7], [-2, -1]],  # decelerate
                is_hold => 1);

# Pre-compile static evaluators
my $a_fn = $alpha->static;
my $s_fn = $size->static;
my $v_fn = $speed->static;

# Spawn particles
my $num_particles = 12;
my $lifetime = 2.0;  # seconds

my @particles;
for my $i (0 .. $num_particles - 1) {
    my $angle = rand() * 3.14159 * 2;
    push @particles, {
        spawn  => $i * 0.1,
        vx     => cos($angle) * (30 + rand(20)),
        vy     => sin($angle) * (30 + rand(20)) - 20,  # upward bias
        x      => 40,  # center
        y      => 20,
    };
}

# Simulate
my $dt = 0.1;
my $gravity = 15;

for (my $t = 0; $t < 3.0; $t += $dt) {
    my @frame;
    for my $p (@particles) {
        next if $t < $p->{spawn};
        my $age = ($t - $p->{spawn}) / $lifetime;
        next if $age > 1.0;

        my $a = $a_fn->($age * $alpha->duration);
        my $s = $s_fn->($age * $size->duration);
        my $v = $v_fn->($age * $speed->duration);

        # Update position
        my $px = $p->{x} + $p->{vx} * $v * ($t - $p->{spawn});
        my $py = $p->{y} + ($p->{vy} * $v + $gravity * ($t - $p->{spawn})) * ($t - $p->{spawn});

        push @frame, {
            x => int($px + 0.5),
            y => int($py + 0.5),
            alpha => $a,
            size => $s,
            age => $age,
        };
    }

    # Render ASCII frame
    printf "\nt=%.1fs  particles=%d\n", $t, scalar @frame;
    my @grid;
    for my $y (0 .. 24) {
        $grid[$y] = [(' ') x 80];
    }

    for my $p (sort { $a->{alpha} <=> $b->{alpha} } @frame) {
        next if $p->{x} < 0 || $p->{x} >= 80 || $p->{y} < 0 || $p->{y} >= 25;
        my $ch = $p->{alpha} > 0.7 ? '@'
               : $p->{alpha} > 0.3 ? 'o'
               : $p->{alpha} > 0.1 ? '.'
               : ' ';
        $ch = '*' if $p->{size} > 1.2;
        $grid[$p->{y}][$p->{x}] = $ch;
    }

    for my $row (@grid) {
        my $line = join('', @$row);
        print "$line\n" if $line =~ /\S/;
    }
}
