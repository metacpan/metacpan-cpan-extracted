#!/usr/bin/env perl
# KV-based leader election.
#
# Each candidate tries to KV::create('leader', $self_id). The KV bucket
# enforces "Nats-Expected-Last-Subject-Sequence: 0" so create succeeds
# for exactly one candidate; the rest see 'wrong last sequence'. The
# leader refreshes the entry with a compare-and-swap on its own
# revision before the bucket's max_age expires it. A leader that stalls
# past max_age finds its refresh refused and stands down instead of
# overwriting the new leader.
#
# Run multiple instances simultaneously to see one win:
#   perl leader_election.pl &
#   perl leader_election.pl &
#   perl leader_election.pl &
#
# Env: NATS_HOST, NATS_PORT, BUCKET (default "election").

use strict;
use warnings;
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::KV;

my $bucket = $ENV{BUCKET} // 'election';
my $self_id = "host-$$";   # in real use: hostname or k8s pod id
my $key = 'leader';
my $tick = 5;              # refresh every 5s
my $ttl  = 15;             # bucket max_age = 3 * tick

my $nats = EV::Nats->new(
    host     => $ENV{NATS_HOST} // '127.0.0.1',
    port     => $ENV{NATS_PORT} // 4222,
    on_error => sub { warn "nats: $_[0]\n" },
);
my $js = EV::Nats::JetStream->new(nats => $nats);
my $kv = EV::Nats::KV->new(js => $js, bucket => $bucket, timeout => 1500);

$kv->create_bucket({
    max_age     => $ttl * 1_000_000_000,  # ns
    max_history => 1,
}, sub {
    my (undef, $err) = @_;
    # concurrent candidates race to create the bucket
    warn "create_bucket: $err\n" if $err && $err !~ /already in use|already exists/i;
    contend();
});

sub contend {
    $kv->create($key, $self_id, sub {
        my ($rev, $err) = @_;
        if ($rev) {
            warn "[$self_id] won leadership (rev=$rev)\n";
            return refresh_later($rev);
        }
        warn $err && $err =~ /wrong last sequence/i
            ? "[$self_id] not leader; retrying in ${tick}s\n"
            : "[$self_id] create failed: " . ($err // '?') . "\n";
        my $ct; $ct = EV::timer($tick, 0, sub { undef $ct; contend() });
    });
}

sub refresh_later {
    my ($rev) = @_;
    my $rt; $rt = EV::timer($tick, 0, sub {
        undef $rt;
        $kv->update($key, $self_id, $rev, sub {
            my ($new_rev, $err) = @_;
            return refresh_later($new_rev) if $new_rev;
            warn "[$self_id] lost leadership: $err\n";
            contend();
        });
    });
}

EV::run;
