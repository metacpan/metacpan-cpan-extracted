#!/usr/bin/env perl
# Reverse DNS lookup for IP addresses
# Usage: perl eg/reverse.pl 8.8.8.8 1.1.1.1 2606:4700::6810:84e5
use strict;
use warnings;
use EV;
use EV::cares qw(:status);

my @ips = @ARGV;
@ips = ('8.8.8.8', '1.1.1.1', '9.9.9.9') unless @ips;

my $r = EV::cares->new(timeout => 5);
my $pending = 0;

for my $ip (@ips) {
    $pending++;
    $r->reverse($ip, sub {
        my ($status, @hosts) = @_;
        if ($status == ARES_SUCCESS) {
            printf "%-40s %s\n", $ip, join(', ', @hosts);
        } else {
            printf "%-40s %s\n", $ip, EV::cares::strerror($status);
        }
        EV::break unless --$pending;
    });
}

EV::run;
