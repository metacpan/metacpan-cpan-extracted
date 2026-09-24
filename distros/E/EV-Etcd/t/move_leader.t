#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN {
    unless ($ENV{ETCD_TEST_MOVE_LEADER}) {
        plan skip_all => 'Set ETCD_TEST_MOVE_LEADER=1 to run move_leader test (requires 3-node cluster)';
    }
    eval { require EV };
    plan skip_all => 'EV required' if $@;
}

use EV;
use EV::Etcd;

# Cluster endpoints (from scripts/local_cluster.sh)
my @endpoints = (
    '127.0.0.1:2379',
    '127.0.0.1:22379',
    '127.0.0.1:32379',
);

my $healthy_count = 0;

for my $ep (@endpoints) {
    my $ep_client = EV::Etcd->new(endpoints => [$ep], timeout => 2);
    $ep_client->status(sub {
        my ($resp, $err) = @_;
        $healthy_count++ if !$err && $resp;
        EV::break;
    });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
}

if ($healthy_count < 3) {
    plan skip_all => "Need 3-node cluster (found $healthy_count). Run: ./scripts/local_cluster.sh start";
}

plan tests => 8;

diag("Cluster has $healthy_count healthy nodes");

my $client = EV::Etcd->new(endpoints => \@endpoints);

my @members;
my $current_leader_id;

$client->member_list(sub {
    my ($resp, $err) = @_;
    ok(!$err, 'member_list succeeded');
    @members = @{$resp->{members} || []};
    ok(@members == 3, 'cluster has 3 members');

    for my $m (@members) {
        diag("  Member: $m->{name} ID=$m->{id}");
    }
    EV::break;
});
my $t1 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

my $leader_endpoint;

$client->status(sub {
    my ($resp, $err) = @_;
    ok(!$err, 'status succeeded');
    $current_leader_id = $resp->{leader};
    ok($current_leader_id, "current leader ID: $current_leader_id");
    diag("Current leader: $current_leader_id");
    EV::break;
});
my $t2 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

my $target_id;
for my $m (@members) {
    if ($m->{id} eq $current_leader_id) {
        if ($m->{client_urls} && @{$m->{client_urls}}) {
            my $url = $m->{client_urls}[0];
            $url =~ s|^http://||;
            $leader_endpoint = $url;
            diag("Leader endpoint: $leader_endpoint");
        }
    } else {
        $target_id //= $m->{id};
    }
}

SKIP: {
    skip "Could not find non-leader member", 4 unless $target_id;
    skip "Could not find leader endpoint", 4 unless $leader_endpoint;

    diag("Will transfer leadership to: $target_id");

    # move_leader must be sent to the current leader
    my $leader_client = EV::Etcd->new(endpoints => [$leader_endpoint]);

    $leader_client->move_leader($target_id, sub {
        my ($resp, $err) = @_;
        ok(!$err, 'move_leader succeeded');
        ok($resp, 'move_leader returned response');
        if ($err) {
            diag("move_leader error: " . ($err->{message} // $err));
        } else {
            diag("move_leader response keys: " . join(", ", keys %{$resp || {}}));
        }
        EV::break;
    });
    my $t3 = EV::timer(10, 0, sub { fail('timeout'); EV::break });
    EV::run;

    # Give cluster a moment to stabilize
    my $delay = EV::timer(1, 0, sub { EV::break });
    EV::run;

    my $new_leader_id;
    $client->status(sub {
        my ($resp, $err) = @_;
        ok(!$err, 'status after move_leader succeeded');
        $new_leader_id = $resp->{leader};
        ok($new_leader_id eq $target_id, "leader changed to target ($new_leader_id == $target_id)");
        diag("New leader: $new_leader_id");
        EV::break;
    });
    my $t4 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
    EV::run;
}

done_testing();
