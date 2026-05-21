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

plan tests => 21;

my $etcd = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);
ok($etcd, "created client");

my $done = 0;
my $expected = 9;  # status + alarm + hash_kv + auth_status + put + compact + hash_kv(rev) + delete + defragment

# Test 1: status (already existed but good to verify)
$etcd->status(sub {
    my ($result, $err) = @_;
    ok(!$err, "status: no error");
    ok($result->{version}, "status: has version");
    ok(exists $result->{db_size}, "status: has db_size");
    ok(exists $result->{leader}, "status: has leader");
    ok($result->{header}, "status: has header");
    $done++;
});

# Test 2: alarm GET - list current alarms
$etcd->alarm('GET', sub {
    my ($result, $err) = @_;
    ok(!$err, "alarm GET: no error");
    ok($result->{header}, "alarm GET: has header");
    ok(exists $result->{alarms}, "alarm GET: has alarms array");
    ok(ref($result->{alarms}) eq 'ARRAY', "alarm GET: alarms is an array");
    diag("Current alarms: " . scalar(@{$result->{alarms}}));
    $done++;
});

# Test 3: hash_kv - get hash of KV store
$etcd->hash_kv(sub {
    my ($result, $err) = @_;
    ok(!$err, "hash_kv: no error");
    ok($result->{header}, "hash_kv: has header");
    ok(exists $result->{hash}, "hash_kv: has hash");
    ok(exists $result->{compact_revision}, "hash_kv: has compact_revision");
    diag("KV hash: $result->{hash}, compact_revision: $result->{compact_revision}");
    $done++;
});

# Test 4: auth_status - check if auth is enabled
$etcd->auth_status(sub {
    my ($result, $err) = @_;
    ok(!$err, "auth_status: no error");
    diag("Auth enabled: " . ($result->{enabled} ? "yes" : "no") . ", revision: " . ($result->{auth_revision} // 0));
    $done++;
});

# Test 5: compact - chain compact + hash_kv(revision) + cleanup off the put
# callback so the test plan is deterministic regardless of put RTT.
my $compact_prefix = "/test-compact-$$-" . time();

$etcd->put("$compact_prefix/key1", "value1", sub {
    my ($result, $err) = @_;
    ok(!$err, "compact prep: put succeeded");
    $done++;

    my $compact_revision = $result->{header} && $result->{header}{revision};
    return unless $compact_revision;

    # Test 6: compact at the revision we just created
    $etcd->compact($compact_revision, sub {
        my ($result, $err) = @_;
        ok(!$err, "compact: no error");
        ok($result->{header}, "compact: has header");
        diag("Compacted to revision: $compact_revision");
        $done++;

        # Test 7: hash_kv with revision parameter
        $etcd->hash_kv($compact_revision, sub {
            my ($result, $err) = @_;
            ok(!$err, "hash_kv(revision): no error");
            ok(exists $result->{hash}, "hash_kv(revision): has hash");
            diag("hash_kv at revision $compact_revision: hash=$result->{hash}");
            $done++;

            # Cleanup the test key
            $etcd->delete("$compact_prefix/", { prefix => 1 }, sub {
                $done++;
            });
        });
    });
});

# Test 8: defragment
# Note: defragment can take time on large databases but should complete quickly on test DB
# Note: header may be empty/optional in some etcd versions
$etcd->defragment(sub {
    my ($result, $err) = @_;
    ok(!$err, "defragment: no error");
    diag("Defragment completed" . ($result->{header} ? " (has header)" : " (no header)"));
    $done++;
});

# Note: Not testing move_leader as it requires a cluster with multiple members

my $timer = EV::timer 15, 0, sub { EV::break };
my $check = EV::check sub { EV::break if $done >= $expected };
EV::run;

done_testing();
