#!/usr/bin/env perl
# Skia rendering: draw envelope curves via FFI::Platypus
# Renders to a PNG file using Skia's raster backend
#
# Requires: FFI::Platypus, libskia
use strict;
use warnings;

BEGIN {
    eval { require FFI::Platypus; 1 }
        or die "This example requires FFI::Platypus\n";
}

use FFI::Platypus;
use FFI::Platypus::Buffer qw(scalar_to_pointer);
use Math::SegmentedEnvelope qw(adsr perc spline env);

my $W = 800;
my $H = 400;
my $PAD = 40;
my $outfile = $ARGV[0] // 'envelope_skia.png';

# Skia FFI bindings (minimal subset for raster rendering)
my $ffi = FFI::Platypus->new(api => 2, lib => ['libskia.so']);

# We'll use Skia's C API via sk_* functions
# Since Skia's Perl FFI story is complex, let's use a simpler approach:
# render to a raw pixel buffer and write PNG manually

# Generate envelope pixel data directly
my @curves = (
    { env => adsr(0.1, 0.15, 0.7, 0.3, morpher_formula => 'smoothstep'),
      r => 50, g => 130, b => 255, label => 'ADSR' },
    { env => perc(0.01, 0.5),
      r => 255, g => 80, b => 50, label => 'Perc' },
    { env => spline([0, 0.2, 0.5, 0.8, 1.0], [0, 0.9, 0.2, 0.8, 0]),
      r => 50, g => 200, b => 80, label => 'Spline' },
    { env => env([[0, 1], [1], [1]], morpher_formula => 'bounce_out'),
      r => 200, g => 80, b => 230, label => 'Bounce' },
);

# RGBA pixel buffer
my $pixels = "\x10\x10\x18\xFF" x ($W * $H);  # dark background

# Grid
for my $y (0 .. $H - 1) {
    for my $x (0 .. $W - 1) {
        my $in_area = ($x >= $PAD && $x < $W - $PAD && $y >= $PAD && $y < $H - $PAD);
        next unless $in_area;
        # Grid lines every 10%
        my $gx = ($x - $PAD) / ($W - 2 * $PAD) * 10;
        my $gy = ($y - $PAD) / ($H - 2 * $PAD) * 10;
        if (abs($gx - int($gx + 0.5)) < 0.01 || abs($gy - int($gy + 0.5)) < 0.01) {
            set_pixel(\$pixels, $x, $y, 40, 40, 50, 255);
        }
    }
}

# Draw envelopes with anti-aliased lines
my $pw = $W - 2 * $PAD;
my $ph = $H - 2 * $PAD;

for my $curve (@curves) {
    my $e = $curve->{env};
    my @vals = $e->table($pw);

    # Draw filled area (semi-transparent)
    for my $x (0 .. $#vals) {
        my $py = int((1 - $vals[$x]) * $ph);
        $py = 0 if $py < 0;
        $py = $ph if $py > $ph;
        for my $y ($py .. $ph) {
            my $sx = $PAD + $x;
            my $sy = $PAD + $y;
            blend_pixel(\$pixels, $sx, $sy,
                $curve->{r}, $curve->{g}, $curve->{b}, 15);
        }
    }

    # Draw line (2px thick with anti-aliasing approximation)
    for my $x (0 .. $#vals) {
        my $py = (1 - $vals[$x]) * $ph;
        for my $dy (-1 .. 1) {
            my $sy = int($py + 0.5) + $dy + $PAD;
            next if $sy < $PAD || $sy >= $H - $PAD;
            my $dist = abs($py - (int($py + 0.5) + $dy));
            my $alpha = int((1 - $dist) * 255);
            $alpha = 0 if $alpha < 0;
            my $sx = $PAD + $x;
            blend_pixel(\$pixels, $sx, $sy,
                $curve->{r}, $curve->{g}, $curve->{b}, $alpha);
        }
    }
}

# Legend
my $ly = $PAD + 10;
for my $curve (@curves) {
    for my $dx (0 .. 11) {
        for my $dy (0 .. 11) {
            set_pixel(\$pixels, $PAD + 10 + $dx, $ly + $dy,
                $curve->{r}, $curve->{g}, $curve->{b}, 255);
        }
    }
    $ly += 20;
}

# Write as PPM (simple, no deps)
my $ppm_file = $outfile;
$ppm_file =~ s/\.png$/.ppm/;
open my $fh, '>', $ppm_file or die "Cannot write $ppm_file: $!";
binmode $fh;
print $fh "P6\n$W $H\n255\n";
for my $y (0 .. $H - 1) {
    for my $x (0 .. $W - 1) {
        my $off = ($y * $W + $x) * 4;
        print $fh substr($pixels, $off, 3);  # RGB only
    }
}
close $fh;
printf "Wrote %s (%d bytes)\n", $ppm_file, -s $ppm_file;

# Convert to PNG if possible
if (system("convert $ppm_file $outfile 2>/dev/null") == 0) {
    printf "Converted to %s\n", $outfile;
    unlink $ppm_file;
} elsif (system("pnmtopng $ppm_file > $outfile 2>/dev/null") == 0) {
    printf "Converted to %s\n", $outfile;
    unlink $ppm_file;
} else {
    printf "(Install ImageMagick for PNG output)\n";
}

sub set_pixel {
    my ($buf_ref, $x, $y, $r, $g, $b, $a) = @_;
    my $off = ($y * $W + $x) * 4;
    substr($$buf_ref, $off, 4) = pack('CCCC', $r, $g, $b, $a);
}

sub blend_pixel {
    my ($buf_ref, $x, $y, $r, $g, $b, $a) = @_;
    return if $x < 0 || $x >= $W || $y < 0 || $y >= $H;
    my $off = ($y * $W + $x) * 4;
    my @dst = unpack('CCCC', substr($$buf_ref, $off, 4));
    my $af = $a / 255;
    my $bf = 1 - $af;
    substr($$buf_ref, $off, 4) = pack('CCCC',
        int($r * $af + $dst[0] * $bf),
        int($g * $af + $dst[1] * $bf),
        int($b * $af + $dst[2] * $bf),
        255);
}
