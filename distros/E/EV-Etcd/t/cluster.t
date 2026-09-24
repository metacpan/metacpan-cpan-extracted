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

plan tests => 18;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

my @members;
my $self_member_id;

$client->member_list(sub {
    my ($resp, $err) = @_;
    ok(!$err, 'member_list succeeded');
    ok($resp->{header}, 'response has header');
    ok(ref($resp->{members}) eq 'ARRAY', 'response has members array');
    ok(scalar @{$resp->{members}} > 0, 'cluster has at least one member');

    @members = @{$resp->{members} || []};
    if (@members) {
        $self_member_id = $members[0]->{id};
        diag("Cluster has " . scalar(@members) . " member(s)");
        for my $m (@members) {
            diag("  Member $m->{id}: $m->{name}");
            diag("    peer_urls: " . join(', ', @{$m->{peer_urls} || []}));
            diag("    client_urls: " . join(', ', @{$m->{client_urls} || []}));
        }
    }
    EV::break;
});
my $t1 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

SKIP: {
    skip "no members returned", 2 unless @members;

    my $member = $members[0];
    ok(exists $member->{id}, 'member has id field');
    ok(ref($member->{peer_urls}) eq 'ARRAY', 'member has peer_urls array');
}

# Before the invalid-id calls below: some etcd 3.5 builds (Debian bookworm)
# drop the gRPC connection on member_remove/update with an invalid id
our $added_member_id;
our $cluster_client = $client;
# Never bound, as the learner never starts; per-run to avoid leftover members
my $peer_url = sprintf 'http://127.0.0.1:%d', 20000 + $$ % 10000;
$client->member_add([$peer_url], { is_learner => 1 }, sub {
    my ($resp, $err) = @_;
    ok(!$err, 'member_add (learner) succeeded');
    ok($resp->{header}, 'member_add response has header');
    ok($resp->{member}, 'member_add response has member info');

    if ($resp->{member}) {
        $added_member_id = $resp->{member}{id};
        diag("Added learner member: id=$added_member_id");
        diag("  peer_urls: " . join(', ', @{$resp->{member}{peer_urls} || []}));
        diag("  is_learner: " . ($resp->{member}{is_learner} ? 'yes' : 'no'));
    }
    EV::break;
});
my $t1b = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

# Promotion requires a caught-up learner, and this one never runs
SKIP: {
    skip "no learner member to promote", 3 unless $added_member_id;

    $client->member_promote($added_member_id, sub {
        my ($resp, $err) = @_;
        ok($err, 'member_promote fails for non-running learner (expected)');
        ok(ref($err) eq 'HASH', 'error is a hashref');
        ok(exists $err->{code}, 'error has code field');
        diag("Expected error for promote: $err->{status} - $err->{message}") if $err;
        EV::break;
    });
    my $t5 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
    EV::run;
}

my $fake_member_id = 999999999;
$client->member_remove($fake_member_id, sub {
    my ($resp, $err) = @_;
    ok($err, 'member_remove with invalid ID returns error');
    ok(ref($err) eq 'HASH', 'error is a hashref');
    ok(exists $err->{code}, 'error has code field');
    diag("Expected error for invalid member_remove: $err->{status} - $err->{message}") if $err;
    EV::break;
});
my $t2 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$client->member_update($fake_member_id, ['http://127.0.0.1:12345'], sub {
    my ($resp, $err) = @_;
    ok($err, 'member_update with invalid ID returns error');
    ok(ref($err) eq 'HASH', 'error is a hashref');
    ok(exists $err->{code}, 'error has code field');
    diag("Expected error for invalid member_update: $err->{status} - $err->{message}") if $err;
    EV::break;
});
my $t3 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

# Removes the learner even if a step above timed out
END {
    if ($added_member_id && $cluster_client) {
        $cluster_client->member_remove($added_member_id, sub {
            my ($r, $e) = @_;
            diag($e ? "Cleanup: failed to remove learner" : "Cleanup: removed learner member");
            EV::break;
        });
        my $te = EV::timer(5, 0, sub { EV::break });
        EV::run;
    }
}

done_testing();
