#!/usr/bin/env perl
# Color gradient generation using envelopes for R, G, B channels
use strict;
use warnings;
use Math::SegmentedEnvelope qw(env spline);

# Sunset gradient: dark blue -> orange -> red -> dark purple
my $r = spline([0, 0.3, 0.6, 0.8, 1.0], [0.1, 0.9, 1.0, 0.8, 0.2]);
my $g = spline([0, 0.3, 0.5, 0.7, 1.0], [0.1, 0.5, 0.3, 0.1, 0.0]);
my $b = spline([0, 0.2, 0.5, 0.8, 1.0], [0.4, 0.2, 0.1, 0.2, 0.3]);

my $width = 72;
print "Sunset gradient ($width steps):\n";
render_gradient($r, $g, $b, $width);

# Fire gradient: black -> red -> orange -> yellow -> white
my $fr = env([[0, 1, 1, 1],    [0.3, 0.3, 0.4], [2, 1, 1]]);
my $fg = env([[0, 0, 0.7, 1],  [0.3, 0.3, 0.4], [1, 2, 1]]);
my $fb = env([[0, 0, 0, 0.8],  [0.3, 0.3, 0.4], [1, 1, 2]]);

print "\nFire gradient:\n";
render_gradient($fr, $fg, $fb, $width);

# Ocean: deep blue -> teal -> foam white
my $or = spline([0, 0.5, 0.8, 1.0], [0.0, 0.0, 0.6, 0.9]);
my $og = spline([0, 0.4, 0.7, 1.0], [0.1, 0.4, 0.7, 0.95]);
my $ob = spline([0, 0.3, 0.6, 1.0], [0.3, 0.6, 0.8, 1.0]);

print "\nOcean gradient:\n";
render_gradient($or, $og, $ob, $width);

# Rainbow using phase-shifted sine morphers
my $rr = env([[0, 1, 0, 0, 1], [0.25, 0.25, 0.25, 0.25], [2, -2, 1, 2]],
             is_morph => 1, morpher_formula => 'smoothstep');
my $rg = env([[0, 0, 1, 0, 0], [0.25, 0.25, 0.25, 0.25], [-2, 2, -2, 1]],
             is_morph => 1, morpher_formula => 'smoothstep');
my $rb = env([[1, 0, 0, 1, 1], [0.25, 0.25, 0.25, 0.25], [-2, 1, 2, -2]],
             is_morph => 1, morpher_formula => 'smoothstep');

print "\nRainbow gradient:\n";
render_gradient($rr, $rg, $rb, $width);

# Output CSS gradient
print "\nCSS equivalent (sunset):\n";
print "background: linear-gradient(to right";
my $rs = $r->static;
my $gs = $g->static;
my $bs = $b->static;
for my $pct (0, 25, 50, 75, 100) {
    my $t = $pct / 100;
    printf ",\n  rgb(%d,%d,%d) %d%%",
        int($rs->($t) * 255 + 0.5),
        int($gs->($t) * 255 + 0.5),
        int($bs->($t) * 255 + 0.5),
        $pct;
}
print "\n);\n";

sub render_gradient {
    my ($r, $g, $b, $w) = @_;
    my $rs = $r->static;
    my $gs = $g->static;
    my $bs = $b->static;
    my $rd = $r->duration;
    my $gd = $g->duration;
    my $bd = $b->duration;

    # 24-bit color terminal output
    my $use_color = -t STDOUT && $ENV{TERM} && $ENV{TERM} ne 'dumb';

    for my $row (0 .. 1) {
        for my $i (0 .. $w - 1) {
            my $t = $i / ($w - 1);
            my $rv = int($rs->($t * $rd) * 255 + 0.5);
            my $gv = int($gs->($t * $gd) * 255 + 0.5);
            my $bv = int($bs->($t * $bd) * 255 + 0.5);
            $rv = 0 if $rv < 0; $rv = 255 if $rv > 255;
            $gv = 0 if $gv < 0; $gv = 255 if $gv > 255;
            $bv = 0 if $bv < 0; $bv = 255 if $bv > 255;

            if ($use_color) {
                printf "\e[48;2;%d;%d;%dm ", $rv, $gv, $bv;
            } else {
                # ASCII fallback: brightness character
                my $lum = ($rv * 0.299 + $gv * 0.587 + $bv * 0.114) / 255;
                my @chars = (' ', '.', ':', '-', '=', '+', '*', '#', '@');
                print $chars[int($lum * $#chars + 0.5)];
            }
        }
        print $use_color ? "\e[0m\n" : "\n";
    }

    # Numeric RGB strip
    for my $i (0, int($w/4), int($w/2), int(3*$w/4), $w-1) {
        my $t = $i / ($w - 1);
        printf "  [%3d] rgb(%3d,%3d,%3d)\n", $i,
            int($rs->($t * $rd) * 255 + 0.5),
            int($gs->($t * $gd) * 255 + 0.5),
            int($bs->($t * $bd) * 255 + 0.5);
    }
}
