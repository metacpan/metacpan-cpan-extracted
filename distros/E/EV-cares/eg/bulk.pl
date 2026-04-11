#!/usr/bin/env perl
# Bulk-resolve a list of hostnames from stdin or a file
# Usage: cat domains.txt | perl eg/bulk.pl
#        perl eg/bulk.pl domains.txt
use strict;
use warnings;
use EV;
use EV::cares qw(:status);

my $r = EV::cares->new(
    timeout => 3,
    tries   => 2,
);

my $pending = 0;
my ($ok, $fail) = (0, 0);
my $t0 = EV::now;

while (<>) {
    chomp;
    next unless length;
    my $name = $_;
    $pending++;

    $r->resolve($name, sub {
        my ($status, @addrs) = @_;
        if ($status == ARES_SUCCESS) {
            printf "%s\t%s\n", $name, join("\t", @addrs);
            $ok++;
        } else {
            printf STDERR "%s\tERROR\t%s\n", $name, EV::cares::strerror($status);
            $fail++;
        }
        EV::break unless --$pending;
    });
}

EV::run if $pending;

my $elapsed = EV::now - $t0;
printf STDERR "--- %d ok, %d failed, %.3fs (%.0f/s)\n",
    $ok, $fail, $elapsed, ($ok + $fail) / ($elapsed || 1);
