#!/usr/bin/env perl
# End-to-end mail-deliverability probe: MX -> A -> TCP connect to :25.
# Demonstrates a real DNS-driven workflow.
# Usage: perl eg/mta_probe.pl example.com
use strict;
use warnings;
use EV;
use EV::cares qw(:all);
use IO::Socket::IP;
use Time::HiRes ();

my $domain = shift or die "usage: $0 DOMAIN\n";
my $r = EV::cares->new(timeout => 5);

my $pending = 0;
my @results;

sub bump { EV::break unless --$pending }

# Step 1: get MX records
$pending++;
$r->search($domain, T_MX, sub {
    my ($status, @mx) = @_;
    if ($status != ARES_SUCCESS) {
        warn "MX $domain: " . EV::cares::strerror($status) . "\n";
        return bump();
    }
    @mx = sort { $a->{priority} <=> $b->{priority} } @mx;

    # Step 2: resolve each MX host
    for my $rec (@mx) {
        $pending++;
        my $host = $rec->{host};
        my $prio = $rec->{priority};
        $r->resolve($host, sub {
            my ($s, @addrs) = @_;
            if ($s != ARES_SUCCESS || !@addrs) {
                push @results, { host => $host, prio => $prio,
                                 status => 'no A/AAAA' };
                return bump();
            }
            # Step 3: TCP connect to :25 on the first address
            my $addr = $addrs[0];
            my $t0 = Time::HiRes::time();
            my $sock = IO::Socket::IP->new(
                PeerAddr => $addr, PeerPort => 25,
                Timeout  => 3, Blocking => 1,
            );
            my $ms = sprintf '%.1fms', 1000 * (Time::HiRes::time() - $t0);
            push @results, {
                host   => $host, prio => $prio, addr => $addr,
                status => $sock ? "open ($ms)" : "closed: $@",
            };
            close $sock if $sock;
            bump();
        });
    }
    bump();
});

EV::run;

print "MTA reachability for $domain\n", '=' x 60, "\n";
for my $r (sort { $a->{prio} <=> $b->{prio} } @results) {
    printf "  %3d %-30s %-20s %s\n",
        $r->{prio}, $r->{host}, $r->{addr} // '-', $r->{status};
}
