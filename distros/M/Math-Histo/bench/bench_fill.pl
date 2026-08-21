#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Time::HiRes qw(gettimeofday tv_interval);
use FindBin qw($Bin);
use lib "$Bin/../blib/lib", "$Bin/../blib/arch", "$Bin/../lib";
use Math::Histo;

# Configuration
my $N_SAMPLES = 5_000_000;    # 5 Million samples for bulk runs
my $N_SINGLE  = 2_000_000;    # 2 Million samples for single Perl method calls

say "=" x 78;
say " Math::Histo (Perl XS) Ingestion & Fill Performance Benchmark";
say "=" x 78;
printf(" Perl Version: %s on %s\n", $^V, $^O);
printf(" Sample Size: %s single calls / %s batch elements\n",
    commify($N_SINGLE), commify($N_SAMPLES));
say "=" x 78;

# Prepare pseudo-random dataset
print " Generating benchmark dataset... ";
my @raw_data;
$#raw_data = $N_SAMPLES - 1;
my $packed_data = '';
my $packed_weights = '';

# LCG PRNG for fast deterministic numbers
my $state = 1337;
for (my $i = 0; $i < $N_SAMPLES; $i++) {
    $state = ($state * 1664525 + 1013904223) & 0xFFFFFFFF;
    my $val = ($state % 100000) * 0.001; # [0.0, 100.0)
    $raw_data[$i] = $val if $i < $N_SINGLE;
}
$packed_data = pack('d*', map {
    $state = ($state * 1664525 + 1013904223) & 0xFFFFFFFF;
    ($state % 100000) * 0.001
} 1 .. $N_SAMPLES);
$packed_weights = pack('d*', (1.0) x $N_SAMPLES);
say "Done.\n";

my @results;

# 1. Single Uniform Fill ($h->fill($x))
{
    my $h = Math::Histo->new(bins => 100, min => 0.0, max => 100.0);
    my $t0 = [gettimeofday];
    for (my $i = 0; $i < $N_SINGLE; $i++) {
        $h->fill($raw_data[$i]);
    }
    my $elapsed = tv_interval($t0);
    my $mops = ($N_SINGLE / $elapsed) / 1e6;
    my $ns = ($elapsed / $N_SINGLE) * 1e9;
    push @results, ["1D Uniform Fill (method call)", sprintf("%d ops", $N_SINGLE), sprintf("%.3f s", $elapsed), sprintf("%.2f Mops/s", $mops), sprintf("%.1f ns/op", $ns)];
}

# 2. Single Weighted Fill with sum(w^2)
{
    my $h = Math::Histo->new(bins => 100, min => 0.0, max => 100.0, sumw2 => 1);
    my $t0 = [gettimeofday];
    for (my $i = 0; $i < $N_SINGLE; $i++) {
        $h->fill($raw_data[$i], 1.5);
    }
    my $elapsed = tv_interval($t0);
    my $mops = ($N_SINGLE / $elapsed) / 1e6;
    my $ns = ($elapsed / $N_SINGLE) * 1e9;
    push @results, ["1D Weighted Fill + sumw2", sprintf("%d ops", $N_SINGLE), sprintf("%.3f s", $elapsed), sprintf("%.2f Mops/s", $mops), sprintf("%.1f ns/op", $ns)];
}

# 3. Variable Bin Single Fill (Binary Search)
{
    my @edges = map { $_ * 1.0 } (0 .. 100);
    my $h = Math::Histo->new(edges => \@edges);
    my $t0 = [gettimeofday];
    for (my $i = 0; $i < $N_SINGLE; $i++) {
        $h->fill($raw_data[$i]);
    }
    my $elapsed = tv_interval($t0);
    my $mops = ($N_SINGLE / $elapsed) / 1e6;
    my $ns = ($elapsed / $N_SINGLE) * 1e9;
    push @results, ["1D Variable Bins (100 bins)", sprintf("%d ops", $N_SINGLE), sprintf("%.3f s", $elapsed), sprintf("%.2f Mops/s", $mops), sprintf("%.1f ns/op", $ns)];
}

# 4. Batch Arrayref Fill ($h->fill_n(\@data))
{
    my $h = Math::Histo->new(bins => 100, min => 0.0, max => 100.0);
    my $t0 = [gettimeofday];
    $h->fill_n(\@raw_data);
    my $elapsed = tv_interval($t0);
    my $mops = ($N_SINGLE / $elapsed) / 1e6;
    my $ns = ($elapsed / $N_SINGLE) * 1e9;
    push @results, ["1D Batch Arrayref (fill_n)", sprintf("%d ops", $N_SINGLE), sprintf("%.3f s", $elapsed), sprintf("%.2f Mops/s", $mops), sprintf("%.1f ns/op", $ns)];
}

# 5. Packed Binary Double Batch (fill_packed_f64 / SIMD)
{
    my $h = Math::Histo->new(bins => 100, min => 0.0, max => 100.0);
    my $t0 = [gettimeofday];
    $h->fill_packed_f64($packed_data);
    my $elapsed = tv_interval($t0);
    my $mops = ($N_SAMPLES / $elapsed) / 1e6;
    my $ns = ($elapsed / $N_SAMPLES) * 1e9;
    push @results, ["1D Packed f64 Buffer (SIMD)", sprintf("%d ops", $N_SAMPLES), sprintf("%.3f s", $elapsed), sprintf("%.2f Mops/s", $mops), sprintf("%.2f ns/op", $ns)];
}

# 6. 2D Single Fill ($h2d->fill($x, $y))
{
    my $h2d = Math::Histo::2D->new(xbins => 50, xmin => 0.0, xmax => 100.0, ybins => 50, ymin => 0.0, ymax => 100.0);
    my $t0 = [gettimeofday];
    for (my $i = 0; $i < $N_SINGLE; $i++) {
        $h2d->fill($raw_data[$i], $raw_data[$i]);
    }
    my $elapsed = tv_interval($t0);
    my $mops = ($N_SINGLE / $elapsed) / 1e6;
    my $ns = ($elapsed / $N_SINGLE) * 1e9;
    push @results, ["2D Uniform Fill (method call)", sprintf("%d ops", $N_SINGLE), sprintf("%.3f s", $elapsed), sprintf("%.2f Mops/s", $mops), sprintf("%.1f ns/op", $ns)];
}

# 7. 2D Packed Binary Double Batch (SIMD)
{
    my $h2d = Math::Histo::2D->new(xbins => 50, xmin => 0.0, xmax => 100.0, ybins => 50, ymin => 0.0, ymax => 100.0);
    my $t0 = [gettimeofday];
    $h2d->fill_packed_f64($packed_data, $packed_data);
    my $elapsed = tv_interval($t0);
    my $mops = ($N_SAMPLES / $elapsed) / 1e6;
    my $ns = ($elapsed / $N_SAMPLES) * 1e9;
    push @results, ["2D Packed f64 Buffer (SIMD)", sprintf("%d ops", $N_SAMPLES), sprintf("%.3f s", $elapsed), sprintf("%.2f Mops/s", $mops), sprintf("%.2f ns/op", $ns)];
}

# 8. DDSketch Streaming Quantile Insert ($sketch->insert($x))
{
    my $sketch = Math::Histo::Sketch->new(alpha => 0.01, max_bins => 2048);
    my $t0 = [gettimeofday];
    for (my $i = 0; $i < $N_SINGLE; $i++) {
        $sketch->insert($raw_data[$i]);
    }
    my $elapsed = tv_interval($t0);
    my $mops = ($N_SINGLE / $elapsed) / 1e6;
    my $ns = ($elapsed / $N_SINGLE) * 1e9;
    push @results, ["DDSketch Dynamic Insert", sprintf("%d ops", $N_SINGLE), sprintf("%.3f s", $elapsed), sprintf("%.2f Mops/s", $mops), sprintf("%.1f ns/op", $ns)];
}

# 9. DDSketch Packed Binary Insert
{
    my $sketch = Math::Histo::Sketch->new(alpha => 0.01, max_bins => 2048);
    my $t0 = [gettimeofday];
    $sketch->insert_packed_f64($packed_data);
    my $elapsed = tv_interval($t0);
    my $mops = ($N_SAMPLES / $elapsed) / 1e6;
    my $ns = ($elapsed / $N_SAMPLES) * 1e9;
    push @results, ["DDSketch Packed Buffer", sprintf("%d ops", $N_SAMPLES), sprintf("%.3f s", $elapsed), sprintf("%.2f Mops/s", $mops), sprintf("%.2f ns/op", $ns)];
}

# Print Results Table
say "+" . ("-" x 33) . "+" . ("-" x 14) . "+" . ("-" x 12) . "+" . ("-" x 16) . "+" . ("-" x 12) . "+";
printf("| %-31s | %-12s | %-10s | %-14s | %-10s |\n",
    "Benchmark Operation", "Count", "Time", "Throughput", "Latency");
say "+" . ("=" x 33) . "+" . ("=" x 14) . "+" . ("=" x 12) . "+" . ("=" x 16) . "+" . ("=" x 12) . "+";
for my $r (@results) {
    printf("| %-31s | %12s | %10s | %14s | %10s |\n", @$r);
}
say "+" . ("-" x 33) . "+" . ("-" x 14) . "+" . ("-" x 12) . "+" . ("-" x 16) . "+" . ("-" x 12) . "+";

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}
