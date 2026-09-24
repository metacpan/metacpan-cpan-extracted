#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN {
    eval { require EV };
    plan skip_all => 'EV required' if $@;
}

use EV;
use EV::Etcd;

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

$etcd->status(sub {
    my ($result, $err) = @_;
    ok(!$err, "status: no error");
    ok($result->{version}, "status: has version");
    ok(exists $result->{db_size}, "status: has db_size");
    ok(exists $result->{leader}, "status: has leader");
    ok($result->{header}, "status: has header");
    $done++;
});

$etcd->alarm('GET', sub {
    my ($result, $err) = @_;
    ok(!$err, "alarm GET: no error");
    ok($result->{header}, "alarm GET: has header");
    ok(exists $result->{alarms}, "alarm GET: has alarms array");
    ok(ref($result->{alarms}) eq 'ARRAY', "alarm GET: alarms is an array");
    diag("Current alarms: " . scalar(@{$result->{alarms}}));
    $done++;
});

$etcd->hash_kv(sub {
    my ($result, $err) = @_;
    ok(!$err, "hash_kv: no error");
    ok($result->{header}, "hash_kv: has header");
    ok(exists $result->{hash}, "hash_kv: has hash");
    ok(exists $result->{compact_revision}, "hash_kv: has compact_revision");
    diag("KV hash: $result->{hash}, compact_revision: $result->{compact_revision}");
    $done++;
});

$etcd->auth_status(sub {
    my ($result, $err) = @_;
    ok(!$err, "auth_status: no error");
    diag("Auth enabled: " . ($result->{enabled} ? "yes" : "no") . ", revision: " . ($result->{auth_revision} // 0));
    $done++;
});

# Chained off the put callback so the plan holds whatever the put's round trip
my $compact_prefix = "/test-compact-$$-" . time();

$etcd->put("$compact_prefix/key1", "value1", sub {
    my ($result, $err) = @_;
    ok(!$err, "compact prep: put succeeded");
    $done++;

    my $compact_revision = $result->{header} && $result->{header}{revision};
    return unless $compact_revision;

    $etcd->compact($compact_revision, sub {
        my ($result, $err) = @_;
        ok(!$err, "compact: no error");
        ok($result->{header}, "compact: has header");
        diag("Compacted to revision: $compact_revision");
        $done++;

        $etcd->hash_kv($compact_revision, sub {
            my ($result, $err) = @_;
            ok(!$err, "hash_kv(revision): no error");
            ok(exists $result->{hash}, "hash_kv(revision): has hash");
            diag("hash_kv at revision $compact_revision: hash=$result->{hash}");
            $done++;

            $etcd->delete("$compact_prefix/", { prefix => 1 }, sub {
                $done++;
            });
        });
    });
});

# Some etcd versions omit the header here
$etcd->defragment(sub {
    my ($result, $err) = @_;
    ok(!$err, "defragment: no error");
    diag("Defragment completed" . ($result->{header} ? " (has header)" : " (no header)"));
    $done++;
});

# move_leader needs a multi-member cluster: t/move_leader.t

my $timer = EV::timer 15, 0, sub { EV::break };
my $check = EV::check sub { EV::break if $done >= $expected };
EV::run;

done_testing();
