#!/usr/bin/env perl
# ASCII envelope visualization
use strict;
use warnings;
use Math::SegmentedEnvelope qw(adsr perc asr);

my @envelopes = (
    ['ADSR',        adsr(0.1, 0.1, 0.7, 0.3)],
    ['Percussive',  perc(0.01, 0.5)],
    ['ASR (pad)',   asr(0.2, 0.5, 0.3)],
    ['Ping-pong',   perc(0.1, 0.4, peak => 1.0)->reverse->delay(0.1)],
);

for my $pair (@envelopes) {
    my ($name, $e) = @$pair;
    plot_envelope($name, $e, 60, 15);
    print "\n";
}

sub plot_envelope {
    my ($name, $e, $width, $height) = @_;
    $width  //= 60;
    $height //= 15;

    my @vals = $e->table($width);
    my $min = $vals[0];
    my $max = $vals[0];
    for (@vals) {
        $min = $_ if $_ < $min;
        $max = $_ if $_ > $max;
    }
    my $range = $max - $min;
    $range = 1 if $range < 0.001;

    printf "%s (%.2fs, %d segments)\n", $name, $e->duration, $e->segments;

    # Build grid
    my @grid;
    for my $y (0 .. $height - 1) {
        $grid[$y] = [(' ') x $width];
    }

    for my $x (0 .. $width - 1) {
        my $y = int(($vals[$x] - $min) / $range * ($height - 1) + 0.5);
        $y = 0 if $y < 0;
        $y = $height - 1 if $y >= $height;
        $grid[$height - 1 - $y][$x] = '*';
    }

    for my $y (0 .. $height - 1) {
        my $level = $min + ($height - 1 - $y) / ($height - 1) * $range;
        printf "%5.2f |%s\n", $level, join('', @{$grid[$y]});
    }
    printf "      +%s\n", '-' x $width;
    printf "       0%s%.2fs\n", ' ' x ($width - 6), $e->duration;
}
