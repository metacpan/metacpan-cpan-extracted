#!/usr/bin/env perl
# Fan-out / gather: submit many subtasks in parallel, gather results.
#
# Pattern: split a job into N sub-jobs, submit them concurrently,
# collect results once they all complete. Pipelining keeps the
# write side dense; demultiplexing-by-handle keeps the read side
# sane even with hundreds of jobs in flight.
use strict;
use warnings;
use EV;
use EV::Gearman;

my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);

sub fanout {
    my ($func, $loads, $cb) = @_;
    my @results;
    my $remaining = scalar @$loads;
    my $had_error;

    for my $i (0 .. $#$loads) {
        $g->submit_job($func, $loads->[$i], sub {
            my ($result, $err) = @_;
            $results[$i] = { result => $result, error => $err };
            $had_error ||= $err;
            $cb->(\@results, $had_error) unless --$remaining;
        });
    }
}

# Demo
fanout(reverse => [map "chunk-$_", 1 .. 20], sub {
    my ($results, $err) = @_;
    if ($err) {
        warn "at least one chunk failed: $err\n";
    } else {
        warn "all ", scalar(@$results), " chunks done\n";
    }
    print "  $_->{result}\n" for @$results;
    EV::break;
});

EV::run;
