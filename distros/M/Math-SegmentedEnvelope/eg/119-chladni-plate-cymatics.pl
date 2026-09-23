#!/usr/bin/env perl
# Chladni Plate Cymatics (Acoustic Standing Waves & Sand Patterns)
# Demonstrates segmented envelopes in wave physics & cymatics:
# - Mode index morphing envelopes (smooth continuous transitions between (m, n) vibrational eigenstates)
# - Acoustic excitation frequency & drive amplitude envelope
# - Sand grain settling & kinetic damping envelope
#
# Generates intricate acoustic nodal patterns, rendered as ASCII art and exported to SVG.
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env adsr perc spline);

my $pi = 3.141592653589793;

# Grid resolution
my $dim = 65; # square plate grid (65x65)
my $half = ($dim - 1) / 2.0;

# 1. Mode parameter envelopes: transitions between modal eigenmodes (m, n)
# Mode 1: (m=2, n=4) -> Mode 2: (m=3, n=5) -> Mode 3: (m=4, n=6)
my $mode_m_env = spline(
    [0.0, 1.0, 2.0, 3.0],
    [2.0, 3.0, 4.0, 5.0],
    resolution => 8, is_hold => 1
);
my $mode_n_env = spline(
    [0.0, 1.0, 2.0, 3.0],
    [3.0, 5.0, 3.0, 6.0],
    resolution => 8, is_hold => 1
);

# 2. Mode superposition mix envelope: balance between symmetric and anti-symmetric modes
my $superpos_env = env(
    [[0.8, -0.6, 0.9, -0.7], [1.0, 1.0, 1.0], [1, -2, 2]],
    is_hold => 1
);

# 3. Vibration amplitude envelope (resonance build-up and decay)
my $drive_amp_env = env(
    [[0.2, 1.0, 0.4, 0.9], [0.8, 1.2, 1.0], [2, -1, 1]],
    is_hold => 1
);

my $sm = $mode_m_env->static;
my $sn = $mode_n_env->static;
my $sp = $superpos_env->static;
my $sa = $drive_amp_env->static;

# Chladni 2D standing wave equation:
# w(x, y) = a * sin(n*pi*x)*sin(m*pi*y) + b * sin(m*pi*x)*sin(n*pi*y)
# Nodal lines occur where displacement w(x, y) = 0
sub chladni_displacement {
    my ($x, $y, $m, $n, $mix) = @_;
    # Normalized plate coordinates [-1, 1]
    my $term1 = sin($n * $pi * $x) * sin($m * $pi * $y);
    my $term2 = sin($m * $pi * $x) * sin($n * $pi * $y);
    return $term1 + $mix * $term2;
}

sub evaluate_cymatics_frame {
    my ($t_sim) = @_;

    my $m = $sm->($t_sim);
    my $n = $sn->($t_sim);
    my $mix = $sp->($t_sim);
    my $amp = $sa->($t_sim);

    my @field;
    for my $iy (0 .. $dim - 1) {
        my $y = ($iy - $half) / $half; # [-1.0 .. 1.0]
        my @row;
        for my $ix (0 .. $dim - 1) {
            my $x = ($ix - $half) / $half;
            my $w = chladni_displacement($x, $y, $m, $n, $mix) * $amp;
            push @row, $w;
        }
        push @field, \@row;
    }
    return (\@field, $m, $n, $mix, $amp);
}

print "Generating Chladni Plate Cymatics (Acoustic Standing Waves)...\n\n";

# Render an expressive frame
my ($field, $cur_m, $cur_n, $cur_mix, $cur_amp) = evaluate_cymatics_frame(1.6);

printf "Cymatics Nodal Pattern (t=1.6s | Mode m=%.2f, n=%.2f | Mix=%.2f | Amplitude=%.2f):\n",
    $cur_m, $cur_n, $cur_mix, $cur_amp;
print "Sand particles accumulate at zero-motion nodal lines (marked with '#'):\n";
print "+" . ("-" x $dim) . "+\n";

# Threshold for nodal line accumulation (where displacement |w| is close to zero)
my $node_threshold = 0.08;

for my $iy (0 .. $dim - 1) {
    print "|";
    for my $ix (0 .. $dim - 1) {
        my $w = abs($field->[$iy][$ix]);
        my $ch = ' ';
        if ($w < $node_threshold * 0.4) {
            $ch = '#'; # high sand concentration
        } elsif ($w < $node_threshold) {
            $ch = '*'; # medium sand concentration
        } elsif ($w < $node_threshold * 1.8) {
            $ch = '.'; # thin boundary
        }
        print $ch;
    }
    print "|\n";
}
print "+" . ("-" x $dim) . "+\n";

# Export Vector SVG Plate
my $svg_file = 'chladni_plate.svg';
open my $sf, '>', $svg_file or die "Cannot open $svg_file: $!\n";
my $svg_size = 520;
my $scale = $svg_size / $dim;

print $sf qq{<svg xmlns="http://www.w3.org/2000/svg" width="$svg_size" height="$svg_size" style="background:#0c0f14">\n};
print $sf qq{  <rect x="0" y="0" width="$svg_size" height="$svg_size" fill="#0d1117" stroke="#30363d" stroke-width="3"/>\n};
print $sf qq{  <defs>\n};
print $sf qq{    <radialGradient id="sandGlow" cx="50%" cy="50%" r="50%">\n};
print $sf qq{      <stop offset="0%" stop-color="#f6e05e" stop-opacity="0.9"/>\n};
print $sf qq{      <stop offset="100%" stop-color="#d69e2e" stop-opacity="0.1"/>\n};
print $sf qq{    </radialGradient>\n};
print $sf qq{  </defs>\n};

for my $iy (0 .. $dim - 1) {
    for my $ix (0 .. $dim - 1) {
        my $w = abs($field->[$iy][$ix]);
        if ($w < $node_threshold) {
            my $cx = sprintf("%.1f", $ix * $scale + $scale / 2);
            my $cy = sprintf("%.1f", $iy * $scale + $scale / 2);
            my $r = sprintf("%.2f", (1.0 - $w / $node_threshold) * ($scale * 0.55));
            my $opacity = sprintf("%.2f", 1.0 - ($w / $node_threshold) * 0.7);
            print $sf qq{  <circle cx="$cx" cy="$cy" r="$r" fill="#ecc94b" opacity="$opacity"/>\n};
        }
    }
}

print $sf qq{  <circle cx="260" cy="260" r="4" fill="#e53e3e"/>\n}; # Center excitation point
print $sf qq{</svg>\n};
close $sf;

printf "\nExported Chladni nodal plate to %s (520x520 vector graphic)\n", $svg_file;
