#!/usr/bin/env perl
# Envelope oscilloscope: real-time terminal scope with trigger detection
# Type envelope commands, see waveform + derivative + trigger markers
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr perc env spline);
use Time::HiRes qw(time sleep);

$| = 1;

my $width  = 72;
my $height = 16;
my $div_h  = 7;   # derivative display height

my $e = adsr(0.1, 0.1, 0.7, 0.3);
my $trigger_level = 0.5;
my $running = 1;
my $sweep_speed = 1.0;

sub render {
    my ($env, $t_offset) = @_;
    $t_offset //= 0;

    my $dur = $env->duration * $sweep_speed;
    my @vals = $env->table($width);

    # Derivative for trigger detection
    my $deriv = $env->resample($width)->derivative;
    my @dvals = $deriv->table($width);

    my ($vmin, $vmax) = ($vals[0], $vals[0]);
    for (@vals) { $vmin = $_ if $_ < $vmin; $vmax = $_ if $_ > $vmax }
    my $vrange = $vmax - $vmin || 1;

    my ($dmin, $dmax) = ($dvals[0], $dvals[0]);
    for (@dvals) { $dmin = $_ if $_ < $dmin; $dmax = $_ if $_ > $dmax }
    my $drange = $dmax - $dmin || 1;

    # Find trigger points (rising edge crossing trigger_level)
    my @triggers;
    for my $x (1 .. $#vals) {
        if ($vals[$x-1] < $trigger_level && $vals[$x] >= $trigger_level) {
            push @triggers, $x;
        }
    }

    # Main waveform
    my @grid;
    for my $y (0 .. $height - 1) { $grid[$y] = [(' ') x $width] }
    for my $x (0 .. $width - 1) {
        my $y = int(($vals[$x] - $vmin) / $vrange * ($height - 1) + 0.5);
        $y = 0 if $y < 0; $y = $height - 1 if $y >= $height;
        $grid[$height - 1 - $y][$x] = '#';
    }

    # Trigger level line
    my $trig_y = $height - 1 - int(($trigger_level - $vmin) / $vrange * ($height - 1) + 0.5);
    $trig_y = 0 if $trig_y < 0; $trig_y = $height - 1 if $trig_y >= $height;
    for my $x (0 .. $width - 1) {
        $grid[$trig_y][$x] = '-' if $grid[$trig_y][$x] eq ' ';
    }

    # Trigger markers
    for my $tx (@triggers) {
        $grid[0][$tx] = 'T' if $tx < $width;
    }

    # Derivative display
    my @dgrid;
    for my $y (0 .. $div_h - 1) { $dgrid[$y] = [(' ') x $width] }
    for my $x (0 .. $width - 1) {
        my $y = int(($dvals[$x] - $dmin) / $drange * ($div_h - 1) + 0.5);
        $y = 0 if $y < 0; $y = $div_h - 1 if $y >= $div_h;
        $dgrid[$div_h - 1 - $y][$x] = '.';
    }
    # Zero line
    my $zero_y = $div_h - 1 - int((0 - $dmin) / $drange * ($div_h - 1) + 0.5);
    if ($zero_y >= 0 && $zero_y < $div_h) {
        for my $x (0 .. $width - 1) {
            $dgrid[$zero_y][$x] = '-' if $dgrid[$zero_y][$x] eq ' ';
        }
    }

    # Output
    print "\e[H";
    printf " SCOPE  dur=%.2fs  trig=%.2f  sweep=%.1fx  triggers=%d\n",
        $env->duration, $trigger_level, $sweep_speed, scalar @triggers;
    printf " range=[%.3f, %.3f]  morpher=%s\n\n",
        $vmin, $vmax, $env->morpher_formula // 'default';

    # Waveform
    for my $y (0 .. $height - 1) {
        my $level = $vmin + ($height - 1 - $y) / ($height - 1) * $vrange;
        printf "%6.2f|%s|\n", $level, join('', @{$grid[$y]});
    }
    printf "      +%s+\n", '-' x $width;

    # Derivative
    print " d/dt:\n";
    for my $y (0 .. $div_h - 1) {
        printf "      |%s|\n", join('', @{$dgrid[$y]});
    }
    printf "      +%s+\n", '-' x $width;
    printf "       0%s%.2fs\n", ' ' x ($width - 7), $env->duration;
}

# Commands
my @cmds = (
    "adsr 0.1 0.1 0.7 0.3",
    "perc 0.01 0.5",
    "formula bounce_out",
    "formula elastic_out",
    "formula smoothstep",
    "spline 0,0 0.2,1 0.5,0.3 0.8,0.9 1,0",
    "adsr 0.05 0.2 0.5 0.5",
    "formula cubic_inout",
);

print "\e[2J";

for my $cmd (@cmds) {
    my @args = split /\s+/, $cmd;
    my $op = shift @args;

    if ($op eq 'adsr') {
        $e = adsr(map { $_ + 0 } @args);
    } elsif ($op eq 'perc') {
        $e = perc(map { $_ + 0 } @args);
    } elsif ($op eq 'formula') {
        $e->morpher_formula($args[0]);
    } elsif ($op eq 'spline') {
        my (@t, @v);
        for (@args) { my ($t,$v) = split /,/; push @t, $t+0; push @v, $v+0 }
        $e = spline(\@t, \@v);
    }

    # Animate for 1 second
    my $frames = 8;
    for my $f (0 .. $frames - 1) {
        render($e, $f / $frames);
        printf "\n > %s\n", $cmd;
        sleep(0.12);
    }
}

print "\e[", $height + $div_h + 12, "H\n";
