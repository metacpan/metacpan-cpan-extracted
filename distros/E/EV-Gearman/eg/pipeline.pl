#!/usr/bin/perl
# Pipeline N foreground jobs concurrently — they multiplex over one
# connection, distinguished by their server-assigned handles.
use strict;
use warnings;
use EV;
use EV::Gearman;
use Time::HiRes qw(time);

my $N = $ARGV[0] // 1000;

my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);

my $start = time;
my $done  = 0;

for my $i (1..$N) {
    $g->submit_job(reverse => "item-$i", sub {
        my ($r, $e) = @_;
        $done++;
        if ($done == $N) {
            my $dt = time - $start;
            printf "%d jobs in %.2fs (%.0f rps)\n", $N, $dt, $N / $dt;
            EV::break;
        }
    });
}

EV::run;
