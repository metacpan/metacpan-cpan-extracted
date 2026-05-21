#!/usr/bin/env perl
# Per-host resolution latency with a tiny histogram bar.
# Usage: perl eg/timing.pl [host ...]
use strict;
use warnings;
use EV;
use EV::cares qw(:status);
use Time::HiRes ();

my @hosts = @ARGV ? @ARGV : qw(
    google.com cloudflare.com github.com amazon.com wikipedia.org
    netflix.com apple.com microsoft.com reddit.com perl.org
);

my $r = EV::cares->new(timeout => 3, tries => 2);
my @rows;
my $pending = 0;

for my $h (@hosts) {
    $pending++;
    my $t0 = Time::HiRes::time();
    $r->resolve($h, sub {
        my $ms = (Time::HiRes::time() - $t0) * 1000;
        push @rows, [$h, $ms, $_[0]];
        EV::break unless --$pending;
    });
}
EV::run;

@rows = sort { $a->[1] <=> $b->[1] } @rows;
my $max = $rows[-1][1] || 1;
for my $row (@rows) {
    my $bar = '#' x int(40 * $row->[1] / $max);
    printf "%-25s %6.1f ms  %s%s\n", $row->[0], $row->[1], $bar,
        $row->[2] != ARES_SUCCESS ? ' [FAIL]' : '';
}

my @ok = grep { $_->[2] == ARES_SUCCESS } @rows;
if (@ok) {
    printf "\n n=%d  min=%.1f  median=%.1f  max=%.1f  ms\n",
        scalar @ok, $ok[0][1], $ok[int(@ok / 2)][1], $ok[-1][1];
}
