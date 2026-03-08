#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

# Skip if EV not available
BEGIN {
    eval { require EV };
    plan skip_all => 'EV required' if $@;
}

use EV;
use EV::Etcd;

# Check if etcd is available
my $etcd_available = 0;
eval {
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        timeout => 2,
    );
    $client->status(sub {
        my ($resp, $err) = @_;
        $etcd_available = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};

plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $etcd_available;

plan tests => 22;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

my $election_name = "test-election-$$-" . time();
my $lease_id;
my $leader_key;

# Test 1-2: Grant a lease for the election
$client->lease_grant(30, sub {
    my ($resp, $err) = @_;
    ok(!$err, 'lease_grant succeeded');
    ok($resp->{id}, 'got lease id');
    $lease_id = $resp->{id};
    EV::break;
});
my $t1 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

SKIP: {
    skip "no lease id", 15 unless $lease_id;

    # Test 3-6: Campaign for leadership
    $client->election_campaign($election_name, $lease_id, "initial-value", sub {
        my ($resp, $err) = @_;
        ok(!$err, 'election_campaign succeeded');
        ok($resp->{header}, 'response has header');
        ok($resp->{leader}, 'response has leader key');

        if ($resp->{leader}) {
            $leader_key = $resp->{leader};
            ok($leader_key->{name}, 'leader key has name');
            diag("Elected as leader:");
            diag("  name: $leader_key->{name}");
            diag("  key: $leader_key->{key}");
            diag("  rev: $leader_key->{rev}");
            diag("  lease: $leader_key->{lease}");
        } else {
            fail('leader key has name');
        }
        EV::break;
    });
    my $t2 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
    EV::run;

    SKIP: {
        skip "no leader key", 11 unless $leader_key;

        # Test 7-9: Get current leader
        $client->election_leader($election_name, sub {
            my ($resp, $err) = @_;
            ok(!$err, 'election_leader succeeded');
            ok($resp->{header}, 'leader response has header');
            ok($resp->{kv}, 'leader response has kv');

            if ($resp->{kv}) {
                diag("Current leader value: $resp->{kv}{value}");
                is($resp->{kv}{value}, "initial-value", 'leader value matches');
            } else {
                fail('leader value matches');
            }
            EV::break;
        });
        my $t3 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
        EV::run;

        # Test 10-11: Proclaim new value
        $client->election_proclaim($leader_key, "updated-value", sub {
            my ($resp, $err) = @_;
            ok(!$err, 'election_proclaim succeeded');
            ok($resp->{header}, 'proclaim response has header');
            EV::break;
        });
        my $t4 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
        EV::run;

        # Test 12-13: Verify updated value
        $client->election_leader($election_name, sub {
            my ($resp, $err) = @_;
            ok(!$err, 'election_leader after proclaim succeeded');
            if ($resp->{kv}) {
                is($resp->{kv}{value}, "updated-value", 'proclaimed value matches');
            } else {
                fail('proclaimed value matches');
            }
            EV::break;
        });
        my $t5 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
        EV::run;

        # Test 14-15: Resign leadership
        $client->election_resign($leader_key, sub {
            my ($resp, $err) = @_;
            ok(!$err, 'election_resign succeeded');
            ok($resp->{header}, 'resign response has header');
            EV::break;
        });
        my $t6 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
        EV::run;

        # Test 16: Verify no leader after resign
        $client->election_leader($election_name, sub {
            my ($resp, $err) = @_;
            ok($err, 'election_leader after resign returns error (no leader)');
            if ($err) {
                diag("Expected error after resign: $err->{status} - $err->{message}");
            }
            EV::break;
        });
        my $t7 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
        EV::run;
    }
}

# Test 17-22: election_observe streaming test
{
    my $observe_election = "observe-test-$$-" . time();
    my $observe_lease_id;
    my @observed_events;
    my $observe_leader_key;

    # Grant a lease for this test
    $client->lease_grant(30, sub {
        my ($resp, $err) = @_;
        $observe_lease_id = $resp->{id} if !$err;
        EV::break;
    });
    my $tl = EV::timer(5, 0, sub { EV::break });
    EV::run;

    SKIP: {
        skip "no observe lease id", 5 unless $observe_lease_id;

        # Test 17: Start observing the election
        $client->election_observe($observe_election, sub {
            my ($resp, $err) = @_;
            if ($err) {
                # Stream ended or error - this is expected after resign
                push @observed_events, { error => $err };
            } else {
                push @observed_events, $resp;
                diag("Observed leader change: " . ($resp->{kv} ? $resp->{kv}{value} : 'no kv'));
            }
        });
        pass('election_observe started');

        # Give observe stream time to set up
        my $setup_wait = EV::timer(0.2, 0, sub { EV::break });
        EV::run;

        # Test 18-19: Campaign for leadership (should trigger observe callback)
        $client->election_campaign($observe_election, $observe_lease_id, "observed-value", sub {
            my ($resp, $err) = @_;
            ok(!$err, 'election_campaign for observe test succeeded');
            if ($resp->{leader}) {
                $observe_leader_key = $resp->{leader};
                ok($observe_leader_key->{name}, 'observe leader key has name');
            } else {
                fail('observe leader key has name');
            }
            EV::break;
        });
        my $t8 = EV::timer(5, 0, sub { fail('timeout in observe campaign'); EV::break });
        EV::run;

        # Wait for observe callback to fire - use a check watcher to poll
        my $wait_count = 0;
        my $check_timer;
        $check_timer = EV::timer(0.1, 0.1, sub {
            $wait_count++;
            if (@observed_events || $wait_count > 20) {
                undef $check_timer;
                EV::break;
            }
        });
        my $timeout = EV::timer(3, 0, sub { undef $check_timer; EV::break });
        EV::run;

        # Test 20: Verify we received at least one observed event
        ok(scalar(@observed_events) >= 1, 'received at least one observe event');
        if (@observed_events && $observed_events[0]->{kv}) {
            diag("First observed value: $observed_events[0]->{kv}{value}");
        }

        # Test 21: Verify observed event has correct structure
        SKIP: {
            skip "no observed events", 1 unless @observed_events && $observed_events[0]->{kv};
            is($observed_events[0]->{kv}{value}, "observed-value", 'observed value matches campaign value');
        }

        # Cleanup - resign and revoke lease
        if ($observe_leader_key) {
            $client->election_resign($observe_leader_key, sub { EV::break });
            my $t9 = EV::timer(2, 0, sub { EV::break });
            EV::run;
        }

        if ($observe_lease_id) {
            $client->lease_revoke($observe_lease_id, sub { EV::break });
            my $t10 = EV::timer(2, 0, sub { EV::break });
            EV::run;
        }
    }
}

# Cleanup - revoke the lease
if ($lease_id) {
    $client->lease_revoke($lease_id, sub { EV::break });
    my $t8 = EV::timer(2, 0, sub { EV::break });
    EV::run;
}

done_testing();
