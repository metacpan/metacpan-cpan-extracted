#!/usr/bin/env perl
# PDL integration: vectorized envelope operations and plotting
use strict;
use warnings;

BEGIN {
    eval { require PDL; PDL->import; 1 }
        or die "This example requires PDL (install via: cpanm PDL)\n";
}

use Math::SegmentedEnvelope qw(adsr perc spline);

# Generate envelope as PDL vector via table()
my $e = adsr(0.01, 0.1, 0.7, 0.3, morpher_formula => 'smoothstep');
my $n = 4096;

my @raw = $e->table($n);
my $sig = pdl(\@raw);

printf "Envelope PDL: %s, %d elements\n", ref($sig), $sig->nelem;
printf "  min=%.4f max=%.4f mean=%.4f\n",
    $sig->min, $sig->max, $sig->avg;

# FFT of the envelope (spectral content)
if (eval { require PDL::FFT; 1 }) {
    my $re = $sig->copy;
    my $im = zeroes($n);
    PDL::FFT::fft($re, $im);
    my $mag = sqrt($re**2 + $im**2);
    my $dc = $mag->slice('0');
    printf "\nFFT: DC=%.2f, first 5 bins: %s\n",
        $dc->sclr, $mag->slice('1:5');
}

# Modulate a sine wave with the envelope
my $sr = 44100;
my $freq = 440;
my $t = sequence($n) / $sr;
my $carrier = sin($t * 2 * 3.14159265 * $freq);
my $modulated = $carrier * $sig;

printf "\nModulated signal: rms=%.4f peak=%.4f\n",
    sqrt(($modulated**2)->avg), $modulated->abs->max;

# Resample envelope to different lengths using PDL interpolation
if (eval { require PDL::Interpolate; 1 }) {
    my $x_orig = sequence($n) / $n;
    my $x_new  = sequence(256) / 256;
    # Linear interpolation to downsample
    my $resampled = PDL::Interpolate::interpolate($x_new, $x_orig, $sig);
    printf "\nResampled: %d -> %d points\n", $n, $resampled->nelem;
}

# Spline control points as PDL
my $times  = pdl([0, 0.2, 0.5, 0.8, 1.0]);
my $values = pdl([0, 0.8, 0.3, 0.9, 0]);

my $spl = spline($times->unpdl, $values->unpdl, resolution => 16);
my @spl_raw = $spl->table(512);
my $spl_sig = pdl(\@spl_raw);

printf "\nSpline PDL: nelem=%d min=%.3f max=%.3f\n",
    $spl_sig->nelem, $spl_sig->min, $spl_sig->max;

# Envelope math with PDL (add two envelope signals)
my $e1 = perc(0.01, 0.3, peak => 0.6);
my $e2 = perc(0.05, 0.5, peak => 0.4);
my $s1 = pdl([$e1->table(1024)]);
my $s2 = pdl([$e2->table(1024)]);

my $sum  = $s1 + $s2;       # additive
my $prod = $s1 * $s2;       # ring mod
my $max  = $s1->cat($s2)->xchg(0,1)->maximum;  # pointwise max

printf "\nPDL arithmetic:\n";
printf "  sum:  peak=%.3f\n", $sum->max;
printf "  prod: peak=%.3f\n", $prod->max;
printf "  max:  peak=%.3f\n", $max->max;

# PDL::Graphics::Prima plotting (if available)
if (eval { require PDL::Graphics::Prima::Simple; 1 }) {
    print "\nPlotting with PDL::Graphics::Prima...\n";
    PDL::Graphics::Prima::Simple::line_plot(
        sequence($n) / $n * $e->duration,
        $sig,
        title => 'ADSR Envelope',
    );
}
