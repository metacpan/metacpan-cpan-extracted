#!/usr/bin/env perl
# KV-based leader election.
#
# Each candidate tries to KV::create('leader', $self_id). The KV bucket
# enforces "Nats-Expected-Last-Subject-Sequence: 0" so create succeeds
# for exactly one candidate; the rest see 'wrong last sequence'. The
# leader periodically refreshes the entry (TTL semantics via KV
# bucket's max_age). On leader exit / timeout, another candidate wins.
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
    # Ignore "stream already in use" errors — coordinated startup races.
    my (undef, $err) = @_;
    warn "create_bucket: $err\n" if $err && $err !~ /already in use|already exists/i;

    # Watch for leader changes so all instances log the current state.
    $kv->watch($key, sub {
        my ($k, $value, $op) = @_;
        warn "[election] $op $k = " . ($value // '<deleted>') . "\n";
    });

    contend();
});

sub contend {
    $kv->create($key, $self_id, sub {
        my ($seq, $err) = @_;
        if ($seq) {
            warn "[$self_id] won leadership (seq=$seq)\n";
            schedule_refresh();
        } elsif ($err && $err =~ /wrong last sequence/i) {
            # Someone else holds it — wait then retry.
            warn "[$self_id] not leader; retrying in ${tick}s\n";
            EV::timer($tick, 0, \&contend);
        } else {
            warn "[$self_id] create failed: " . ($err // '?') . "\n";
            EV::timer($tick, 0, \&contend);
        }
    });
}

# Refresh by overwriting the value (max_age expires the entry if we
# stop). On lease loss, contend again.
sub schedule_refresh {
    EV::timer($tick, 0, sub {
        $kv->put($key, $self_id, sub {
            my ($seq, $err) = @_;
            if ($err) {
                warn "[$self_id] refresh failed: $err — re-contending\n";
                contend();
            } else {
                schedule_refresh();
            }
        });
    });
}

EV::run;
