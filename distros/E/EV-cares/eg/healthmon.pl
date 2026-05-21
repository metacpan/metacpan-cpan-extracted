#!/usr/bin/env perl
# Continuous resolver health monitor.
# Pings a list of hosts via multiple upstream resolvers every N seconds
# and prints latency / failure stats.
# Usage: perl eg/healthmon.pl [--interval=N] [--host=NAME ...] [--server=IP ...]
use strict;
use warnings;
use EV;
use EV::cares qw(:status);
use Time::HiRes ();
use Getopt::Long;

my $interval = 10;
my @hosts;
my @servers;
GetOptions(
    'interval=i' => \$interval,
    'host=s'     => \@hosts,
    'server=s'   => \@servers,
) or die "bad options\n";
@hosts   = qw(google.com cloudflare.com github.com)        unless @hosts;
@servers = qw(8.8.8.8 1.1.1.1 9.9.9.9)                     unless @servers;

# one resolver per upstream so we get per-server timing
my %resolver = map {
    $_ => EV::cares->new(servers => [$_], timeout => 3, tries => 1)
} @servers;

sub probe {
    my $now = sprintf '%02d:%02d:%02d', (localtime)[2,1,0];
    print "--- $now\n";
    my $pending = scalar(@servers) * scalar(@hosts);
    return unless $pending;
    for my $srv (@servers) {
        for my $host (@hosts) {
            my $t0 = Time::HiRes::time();
            $resolver{$srv}->resolve($host, sub {
                my ($status, @addrs) = @_;
                my $ms = 1000 * (Time::HiRes::time() - $t0);
                printf "%-15s %-25s %6.1fms %s\n",
                    $srv, $host, $ms,
                    $status == ARES_SUCCESS
                        ? join(',', @addrs[0..($#addrs > 0 ? 1 : 0)])
                        : 'FAIL ' . EV::cares::strerror($status);
                EV::break unless --$pending;
            });
        }
    }
}

probe();
my $w = EV::timer $interval, $interval, \&probe;
EV::run;
