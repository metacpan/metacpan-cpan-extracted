#!/usr/bin/env perl
# Regression test: lease_keepalive must keep renewing the lease. Pre-fix the
# stream sent exactly one LeaseKeepAliveRequest (at setup/reconnect), so the
# lease silently expired one TTL after stream start.
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

plan tests => 4;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

# TTL=5 keeps ~2 renewal periods of stall headroom (renewals at ttl/3) so the
# test survives slow/loaded CI runners; TTL=3 flaked under artificial load.
my $granted_ttl = 5;
my $lease_id;

$client->lease_grant($granted_ttl, sub {
    my ($resp, $err) = @_;
    ok(!$err && $resp->{id}, 'lease_grant succeeded');
    $lease_id = $resp->{id} if !$err;
    EV::break;
});
my $t0 = EV::timer(5, 0, sub { EV::break });
EV::run;

BAIL_OUT('no lease id from lease_grant') unless $lease_id;

# Keepalive ticks arrive as ($resp, $err) on each renewal response
my $ticks = 0;
my $keepalive = $client->lease_keepalive($lease_id, sub {
    my ($resp, $err) = @_;
    return if $err;
    $ticks++;
});
ok($keepalive, 'keepalive stream created');

# Collect ticks for longer than one TTL — without renewal the lease would
# expire at $granted_ttl seconds.
my $t1 = EV::timer($granted_ttl + 2, 0, sub { EV::break });
EV::run;

# The lease must still be alive (pre-fix: ttl reports -1 here)
my $ttl_after;
$client->lease_time_to_live($lease_id, sub {
    my ($resp, $err) = @_;
    $ttl_after = $resp->{ttl} if !$err;
    EV::break;
});
my $t2 = EV::timer(5, 0, sub { EV::break });
EV::run;

ok(defined $ttl_after && $ttl_after > 0, "lease still alive after one TTL (ttl=$ttl_after)");
cmp_ok($ticks, '>=', 2, "keepalive renewed repeatedly ($ticks ticks)");

$keepalive->cancel(sub { EV::break });
EV::run(EV::RUN_ONCE);

$client->lease_revoke($lease_id, sub { EV::break });
my $t3 = EV::timer(5, 0, sub { EV::break });
EV::run;

done_testing();
