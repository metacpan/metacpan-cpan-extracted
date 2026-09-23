#!/usr/bin/env perl
# Data::PubSub::Shared integration: envelope values broadcast to subscribers
# Publisher samples an envelope at regular intervals, subscribers display values
#
# Requires: Data::PubSub::Shared
use strict;
use warnings;

BEGIN {
    eval { require Data::PubSub::Shared; 1 }
        or die "This example requires Data::PubSub::Shared\n";
}

use Math::SegmentedEnvelope qw(adsr);
$| = 1;  # autoflush

# Shared pub/sub channel and ready signal
my $ps    = Data::PubSub::Shared::Str->new(undef, 4096);
my $ready = Data::PubSub::Shared::Int->new(undef, 64);

# Envelope
my $amp = adsr(0.05, 0.1, 0.7, 0.3, morpher_formula => 'smoothstep');
my $amp_s = $amp->static;

my $steps = 40;
my $dt = $amp->duration / $steps;

# Subscribe before fork so children inherit it
my $sub1 = $ps->subscribe;
my $sub2 = $ps->subscribe;

# Subscriber 1: bar display
my $sub1_pid = fork();
die "fork: $!" unless defined $sub1_pid;
if ($sub1_pid == 0) {
    $ready->publish(1);
    my $count = 0;
    while ($count < $steps) {
        my $msg = $sub1->poll_wait(2.0);
        last unless defined $msg;
        last if $msg eq 'END';
        my ($t, $v) = split /,/, $msg;
        my $bar = '#' x int($v * 50 + 0.5);
        printf "[BAR ] t=%5.2f  |%-50s| %.3f\n", $t, $bar, $v;
        $count++;
    }
    exit(0);
}

# Subscriber 2: peak tracker
my $sub2_pid = fork();
die "fork: $!" unless defined $sub2_pid;
if ($sub2_pid == 0) {
    $ready->publish(1);
    my $peak = 0;
    my $count = 0;
    while ($count < $steps) {
        my $msg = $sub2->poll_wait(2.0);
        last unless defined $msg;
        last if $msg eq 'END';
        my ($t, $v) = split /,/, $msg;
        $peak = $v if $v > $peak;
        $count++;
    }
    printf "[PEAK] max=%.4f\n", $peak;
    exit(0);
}

# Wait for both subscribers to be ready
my $rsub = $ready->subscribe_all;
for (1..2) { $rsub->poll_wait(2.0) }

# Publisher: sample envelope and broadcast
for my $i (0 .. $steps - 1) {
    my $t = $i * $dt;
    my $v = $amp_s->($t);
    $ps->publish(sprintf("%.3f,%.6f", $t, $v));
    select(undef, undef, undef, 0.02);
}
$ps->publish('END');

waitpid($_, 0) for ($sub1_pid, $sub2_pid);
printf "[PUB ] done: %d messages published over %.2fs envelope\n",
    $steps, $amp->duration;
