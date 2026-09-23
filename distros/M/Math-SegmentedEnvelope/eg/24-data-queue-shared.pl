#!/usr/bin/env perl
# Data::Queue::Shared integration: envelope samples through a shared queue
# Producer generates envelope-modulated signal, consumer computes stats
#
# Requires: Data::Queue::Shared
use strict;
use warnings;

BEGIN {
    eval { require Data::Queue::Shared; 1 }
        or die "This example requires Data::Queue::Shared\n";
}

use Math::SegmentedEnvelope qw(adsr env);

my $sr = 1000;
my $dur = 2.0;
my $total = int($dur * $sr);

# Envelope
my $amp = adsr(0.05, 0.1, 0.7, 0.3, morpher_formula => 'smoothstep');
my $amp_s = $amp->static;

# Shared queue: Str type for serialized floats, anonymous (fork-inherited)
my $q = Data::Queue::Shared::Str->new(undef, 4096);

my $pid = fork();
die "fork: $!" unless defined $pid;

if ($pid == 0) {
    # Consumer: read values, compute stats
    my ($count, $sum, $min, $max) = (0, 0, 1e9, -1e9);
    while (1) {
        my $v = $q->pop_wait(1.0);
        last unless defined $v;
        last if $v eq 'END';
        my $val = 0 + $v;
        $count++;
        $sum += $val;
        $min = $val if $val < $min;
        $max = $val if $val > $max;
    }
    printf "Consumer: %d samples, range=[%.4f, %.4f], mean=%.4f\n",
        $count, $min, $max, $count > 0 ? $sum / $count : 0;
    exit(0);
}

# Producer: push envelope values
for my $i (0 .. $total - 1) {
    my $t = $i / $sr;
    my $v = $amp_s->($t);
    $q->push(sprintf("%.6f", $v));
}
$q->push('END');

waitpid($pid, 0);
printf "Producer: sent %d samples over shared queue\n", $total;
