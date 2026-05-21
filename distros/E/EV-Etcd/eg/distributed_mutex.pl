#!/usr/bin/env perl
#
# distributed_mutex.pl - Acquire-with-timeout / hold / release pattern for the
# etcd Lock service, with explicit handling for the "lease died while holding"
# case (process froze long enough that etcd revoked the lease — caller's
# critical section is no longer protected).
#
# Usage:
#   $ perl eg/distributed_mutex.pl /jobs/migration "doing work for 5s"
#
# Run two copies in parallel: the second one waits behind the first.
#
use v5.10;
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use EV;
use EV::Etcd;

my $name      = $ARGV[0] // '/jobs/example';
my $work_msg  = $ARGV[1] // 'critical section';
my $work_time = $ARGV[2] // 5;     # seconds the lock is held
my $lock_ttl  = 10;                # seconds; must exceed work_time + slack

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], max_retries => 5);
my ($lease_id, $lock_key, $keepalive, $work_timer, $lease_died);

# 1. Lease for the lock — if we crash, the lock auto-releases after lock_ttl
$client->lease_grant($lock_ttl, sub {
    my ($r, $err) = @_;
    die "lease_grant: $err->{message}\n" if $err;
    $lease_id = $r->{id};
    say "[$$] lease=$lease_id ttl=${lock_ttl}s";

    # 2. Refresh the lease while we work
    $keepalive = $client->lease_keepalive($lease_id, sub {
        my (undef, $kerr) = @_;
        return unless $kerr;
        # Lease died — our lock is gone. Bail out before we corrupt anything.
        $lease_died = 1;
        warn "[$$] keepalive lost ($kerr->{message}) — aborting work\n";
        graceful_exit(2);
    });

    # 3. Acquire the lock. The etcd Lock RPC blocks server-side until
    # granted. There's no client-side cancel for unary calls, so the
    # timer below abandons the response (the late callback is a no-op
    # under the $acquired guard). The lease will still expire on its
    # own ttl if we exit, releasing any partially-granted lock.
    my $acquired;
    my $start = time;
    say "[$$] acquiring lock at $name ...";
    $client->lock($name, $lease_id, sub {
        my ($lr, $lerr) = @_;
        return if $acquired++;   # timer already fired
        if ($lerr) {
            warn "[$$] lock failed: $lerr->{message}\n";
            return graceful_exit(3);
        }
        $lock_key = $lr->{key};
        my $waited = time - $start;
        say "[$$] acquired (waited ${waited}s) — running: $work_msg";

        # 4. Do the work. Real code would do its critical section inside
        # an ev_timer or similar so it remains async with the keepalive.
        $work_timer = EV::timer($work_time, 0, sub {
            return if $lease_died;
            say "[$$] work complete — releasing lock";
            graceful_exit(0);
        });
    });

    # Optional caller-side timeout: cancel after N seconds if we never get the
    # lock. Without this the process can wait forever behind contention.
    my $acquire_timeout = 30;
    my $timer = EV::timer($acquire_timeout, 0, sub {
        return if $acquired++;
        warn "[$$] lock acquire timed out after ${acquire_timeout}s\n";
        graceful_exit(4);
    });
});

my $sigint  = EV::signal('INT',  sub { say "[$$] SIGINT";  graceful_exit(130) });
my $sigterm = EV::signal('TERM', sub { say "[$$] SIGTERM"; graceful_exit(143) });

EV::run;

# --------------------------------------------------------------------------

sub graceful_exit {
    my $code = shift;
    undef $work_timer;

    # Order matters: release the lock (best-effort), revoke the lease, exit.
    my $finish = sub {
        $lease_id ? $client->lease_revoke($lease_id, sub { EV::break })
                  : EV::break;
    };

    if ($lock_key && !$lease_died) {
        $client->unlock($lock_key, sub {
            my (undef, $uerr) = @_;
            warn "[$$] unlock failed: $uerr->{message}\n" if $uerr;
            $finish->();
        });
    } else {
        $finish->();
    }
    my $bail = EV::timer(2, 0, sub { EV::break });
    EV::run;
    exit $code;
}
