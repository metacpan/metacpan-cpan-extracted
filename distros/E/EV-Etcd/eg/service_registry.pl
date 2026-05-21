#!/usr/bin/env perl
#
# service_registry.pl - Register self under /services/<type>/<id>, heartbeat
# via lease keepalive, watch the prefix to discover peers, deregister cleanly
# on shutdown.
#
# Run several copies in parallel — each prints joins/leaves of the others in
# real time. Kill one harshly (kill -9): the others see it leave after
# lease_ttl seconds (etcd revokes the lease, the key disappears, watchers
# get a DELETE event).
#
use v5.10;
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use EV;
use EV::Etcd;

my $service_type = $ARGV[0] // 'web';
my $self_id      = sprintf "%s-%d", ($ENV{HOSTNAME} || 'localhost'), $$;
my $self_value   = "host=$self_id pid=$$ started=" . time();
my $prefix       = "/services/$service_type/";
my $self_key     = "$prefix$self_id";
my $lease_ttl    = 15;

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], max_retries => 5);
my ($lease_id, $keepalive, $watch);

# 1. Lease — keys self-evict if we crash
$client->lease_grant($lease_ttl, sub {
    my ($r, $err) = @_;
    die "lease_grant: $err->{message}\n" if $err;
    $lease_id = $r->{id};
    say "[$self_id] lease=$lease_id ttl=${lease_ttl}s";

    # 2. Heartbeat
    $keepalive = $client->lease_keepalive($lease_id, sub {
        my (undef, $kerr) = @_;
        warn "[$self_id] keepalive: $kerr->{message}\n" if $kerr;
    });

    # 3. Register self
    $client->put($self_key, $self_value, { lease => $lease_id }, sub {
        my (undef, $perr) = @_;
        die "register: $perr->{message}\n" if $perr;
        say "[$self_id] registered at $self_key";
    });
});

# 4. Discover peers by listing the prefix once, then watching for changes
$client->get($prefix, { prefix => 1 }, sub {
    my ($r, $err) = @_;
    return warn "[$self_id] initial list: $err->{message}\n" if $err;
    say "[$self_id] currently registered:";
    for my $kv (@{$r->{kvs} || []}) {
        my $name = substr $kv->{key}, length $prefix;
        next if $name eq $self_id;
        say "  - $name -> $kv->{value}";
    }

    # Resume watching from the revision we just listed at — no race.
    my $start = $r->{header}{revision} + 1;
    $watch = $client->watch($prefix, {
        prefix         => 1,
        start_revision => $start,
    }, sub {
        my ($wr, $werr) = @_;
        return warn "[$self_id] watch: $werr->{message}\n" if $werr;
        for my $ev (@{$wr->{events} || []}) {
            my $name = substr $ev->{kv}{key}, length $prefix;
            next if $name eq $self_id;
            if ($ev->{type} eq 'PUT') {
                say "[$self_id] + $name (joined)";
            } else {
                say "[$self_id] - $name (left)";
            }
        }
    });
});

# Clean shutdown
my $shutdown = sub {
    say "[$self_id] shutting down";
    $watch && $watch->cancel(sub { });
    $keepalive && $keepalive->cancel(sub { });
    if ($lease_id) {
        $client->lease_revoke($lease_id, sub { EV::break });
        my $t = EV::timer(2, 0, sub { EV::break });
        EV::run;
    }
    exit 0;
};
my $sigint  = EV::signal('INT',  $shutdown);
my $sigterm = EV::signal('TERM', $shutdown);

EV::run;
