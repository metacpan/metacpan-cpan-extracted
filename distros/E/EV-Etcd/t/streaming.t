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

plan tests => 11;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

my $test_prefix = "/test-streaming-$$-" . time();

# === lease_keepalive streaming tests ===

# Test 1-4: lease_keepalive receives response
my $lease_id;
my $keepalive_count = 0;

$client->lease_grant(10, sub {
    my ($resp, $err) = @_;
    ok(!$err, 'lease_grant succeeded');
    $lease_id = $resp->{id};
    diag("Granted lease: id=$lease_id, ttl=$resp->{ttl}");
    EV::break;
});
my $t1 = EV::timer(5, 0, sub { fail('lease_grant timeout'); EV::break });
EV::run;
undef $t1;  # Cancel timer

SKIP: {
    skip "no lease id", 4 unless $lease_id;

    my $keepalive_handle = $client->lease_keepalive($lease_id, sub {
        my ($resp, $err) = @_;
        if ($err) {
            diag("Keepalive error: " . (ref($err) ? $err->{message} : $err));
            return;
        }
        $keepalive_count++;
        diag("Keepalive response #$keepalive_count: ttl=$resp->{ttl}");
        if ($keepalive_count >= 1) {
            EV::break;
        }
    });

    ok(defined $keepalive_handle, 'lease_keepalive returns handle');
    isa_ok($keepalive_handle, 'EV::Etcd::Keepalive', 'keepalive handle');

    # Wait for at least one keepalive response
    my $keepalive_timer = EV::timer 5, 0, sub {
        diag("Keepalive timer expired, received $keepalive_count responses");
        EV::break;
    };
    EV::run;

    ok($keepalive_count >= 1, "received at least 1 keepalive response (got $keepalive_count)");

    # Cleanup lease (this will end the keepalive)
    $client->lease_revoke($lease_id, sub {
        my ($resp, $err) = @_;
        diag($err ? "Revoke failed" : "Lease revoked");
    });
    pass('cleanup initiated');
}

# === Watch streaming tests ===

# Test 5-9: watch receives multiple events
my $watch_key = "$test_prefix/watch-stream-test";
my $watch_count = 0;
my $watch_target = 3;

my $watch_handle;
$watch_handle = $client->watch($watch_key, sub {
    my ($resp, $err) = @_;
    if ($err) {
        diag("Watch error: " . (ref($err) ? $err->{message} : $err));
        return;
    }
    if ($resp->{created}) {
        diag("Watch created with id=$resp->{watch_id}");
        return;
    }
    my $event_count = scalar @{$resp->{events} || []};
    $watch_count += $event_count;
    diag("Watch received $event_count event(s), total=$watch_count");
    if ($watch_count >= $watch_target) {
        EV::break;
    }
});

ok(defined $watch_handle, 'watch returns handle');
isa_ok($watch_handle, 'EV::Etcd::Watch', 'watch handle');

# Send multiple put events
for my $i (1..$watch_target) {
    $client->put($watch_key, "value-$i", sub {
        my ($resp, $err) = @_;
        diag("Put $i " . ($err ? "failed" : "completed"));
    });
}

my $watch_timer = EV::timer 10, 0, sub {
    diag("Watch timer expired, received $watch_count events");
    EV::break;
};
EV::run;

ok($watch_count >= 1, "watch received at least 1 event (got $watch_count)");
cmp_ok($watch_count, '>=', $watch_target, "watch received all $watch_target events (streaming works)");

# Test watch cancel - uses callback-based cancel API
my $cancel_done = 0;
$watch_handle->cancel(sub {
    my ($resp, $err) = @_;
    $cancel_done = 1;
    diag("Watch cancel callback: " . ($err ? "error: $err" : "success"));
    EV::break;
});
my $cancel_timer = EV::timer 5, 0, sub {
    diag("Cancel timer expired");
    EV::break;
};
EV::run;

ok($cancel_done, 'watch cancel completed');

# Cleanup
$client->delete("$test_prefix/", { prefix => 1 }, sub {
    diag("Cleanup completed");
});
pass('cleanup completed');

done_testing();
