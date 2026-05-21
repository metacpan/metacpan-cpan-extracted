#!/usr/bin/env perl
# Tiny fault-tolerant resolver pool.
#
# Maintains N independent EV::cares channels each pointed at a different
# upstream.  resolve_pool($name, $cb) issues the query against the next
# healthy channel; on ECONNREFUSED / timeout / SERVFAIL it retries on the
# next pool member.  Failed channels are marked unhealthy for a cooldown
# period, then probed again.
#
# Usage:
#   perl eg/resolver_pool.pl example.com cloudflare.com github.com
use strict;
use warnings;
use EV;
use EV::cares qw(:all);

my @upstreams = (
    ['8.8.8.8', '8.8.4.4'],
    ['1.1.1.1', '1.0.0.1'],
    ['9.9.9.9', '149.112.112.112'],
);

my @pool = map {
    {
        resolver => EV::cares->new(servers => $_, timeout => 3, tries => 1),
        servers  => $_,
        unhealthy_until => 0,
    }
} @upstreams;

# rotate through the pool starting at the next healthy member
my $cursor = 0;
sub pick_member {
    my $now = EV::time;
    for (1 .. @pool) {
        my $m = $pool[$cursor];
        $cursor = ($cursor + 1) % @pool;
        return $m if $m->{unhealthy_until} <= $now;
    }
    return undef;
}

# transient errors that should trigger fail-over to the next member
my %TRANSIENT = map { $_ => 1 } (
    ARES_ECONNREFUSED, ARES_ETIMEOUT, ARES_ESERVFAIL,
    ARES_ENOTINITIALIZED,
);

# Implemented as a named-sub recursion rather than a self-referential
# closure: the latter would create a CV-to-pad reference cycle that perl's
# refcounter cannot collect, leaking one closure per resolve_pool call.
sub resolve_pool {
    my ($name, $cb) = @_;
    _attempt_resolve($name, $cb, 0);
}

sub _attempt_resolve {
    my ($name, $cb, $tried) = @_;
    my $m = pick_member;
    unless ($m) {
        $cb->(ARES_EREFUSED, undef);
        return;
    }
    $tried++;
    $m->{resolver}->resolve($name, sub {
        my ($status, @addrs) = @_;
        if ($status == ARES_SUCCESS) {
            $cb->($status, $m->{servers}, @addrs);
        } elsif ($TRANSIENT{$status} && $tried < @pool) {
            $m->{unhealthy_until} = EV::time + 30; # 30s cooldown
            warn "[pool] @{$m->{servers}} unhealthy ($status: ",
                EV::cares::strerror($status), "); failing over\n";
            _attempt_resolve($name, $cb, $tried);
        } else {
            $cb->($status, $m->{servers}, @addrs);
        }
    });
}

my @names = @ARGV ? @ARGV : ('cloudflare.com', 'google.com', 'github.com');

my $pending = scalar @names;
for my $n (@names) {
    resolve_pool($n, sub {
        my ($status, $servers, @addrs) = @_;
        if ($status == ARES_SUCCESS) {
            printf "%-30s via %-30s -> %s\n",
                $n, "@$servers", join(', ', @addrs);
        } else {
            printf "%-30s FAILED: %s\n", $n, EV::cares::strerror($status);
        }
        EV::break unless --$pending;
    });
}

EV::run;
