#!/usr/bin/env perl
#
# leader_cron.pl - Run a periodic job on exactly one elected leader.
#
# Pattern: campaign for an election lease, run a tick every N seconds while
# this process is leader, resign cleanly on Ctrl-C. Touches three subsystems
# at once (election + lease + keepalive) and is the canonical "exactly one
# worker across the fleet" pattern.
#
# Run two instances of this script side-by-side: only one ticks at a time.
# Kill the leader, the other becomes leader within ~lease_ttl seconds.
#
use v5.10;
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use EV;
use EV::Etcd;

my $election    = "/cron/nightly-aggregator";
my $lease_ttl   = 10;        # seconds; shorter = faster failover, more chatter
my $tick_period = 2;         # how often the leader runs the job
my $value       = "$0/$$";   # what other observers see for this leader

my $client = EV::Etcd->new(
    endpoints   => ['127.0.0.1:2379'],
    max_retries => 5,
);

my ($lease_id, $leader, $keepalive, $tick_timer);

sub fail { my $m = shift; warn "[$$] $m\n"; cleanup_and_exit(1) }

# 1. Grant an election lease
$client->lease_grant($lease_ttl, sub {
    my ($r, $err) = @_;
    fail("lease_grant: $err->{message}") if $err;
    $lease_id = $r->{id};
    say "[$$] lease granted: $lease_id (ttl=$r->{ttl}s)";

    # 2. Keep the lease alive while we run
    $keepalive = $client->lease_keepalive($lease_id, sub {
        my (undef, $kerr) = @_;
        return unless $kerr;
        # NOT_FOUND = the lease expired; we lost leadership unexpectedly
        fail("keepalive lost: $kerr->{message}");
    });

    # 3. Campaign — this blocks until we're elected
    say "[$$] campaigning for $election ...";
    $client->election_campaign($election, $lease_id, $value, sub {
        my ($cresp, $cerr) = @_;
        fail("campaign: $cerr->{message}") if $cerr;
        $leader = $cresp->{leader};
        say "[$$] elected as leader (key=$leader->{key} rev=$leader->{rev})";

        # 4. Tick the cron job every $tick_period seconds while we're leader
        $tick_timer = EV::timer($tick_period, $tick_period, \&do_work);
    });
});

# Clean shutdown on SIGINT/SIGTERM
my $sigint  = EV::signal('INT',  sub { say "[$$] SIGINT";  cleanup_and_exit(0) });
my $sigterm = EV::signal('TERM', sub { say "[$$] SIGTERM"; cleanup_and_exit(0) });

EV::run;

# --------------------------------------------------------------------------

sub do_work {
    my $ts = scalar localtime;
    say "[$$] tick @ $ts — running aggregation";
    # ... real work goes here ...
}

sub cleanup_and_exit {
    my $code = shift // 0;
    undef $tick_timer;
    if ($leader) {
        $client->election_resign($leader, sub {
            $client->lease_revoke($lease_id, sub { EV::break });
        });
    } elsif ($lease_id) {
        $client->lease_revoke($lease_id, sub { EV::break });
    } else {
        EV::break;
    }
    my $bail = EV::timer(2, 0, sub { EV::break });
    EV::run;
    exit $code;
}
