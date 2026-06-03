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

plan tests => 12;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
    max_retries => 3,
);

my $prefix = "/test-watch-reconnect-$$-" . time();

# Test 1-4: Watch with auto_reconnect => 0 receives events and can be cancelled
{
    my $key = "$prefix/no-reconnect";
    my @events;
    my $watch = $client->watch($key, {
        auto_reconnect => 0,
    }, sub {
        my ($resp, $err) = @_;
        return if $err;
        if ($resp->{events} && @{$resp->{events}}) {
            push @events, @{$resp->{events}};
            EV::break if @events >= 1;
        }
    });

    ok(defined $watch, 'watch with auto_reconnect=0 created');
    isa_ok($watch, 'EV::Etcd::Watch');

    # Trigger an event
    $client->put($key, "test-no-reconnect", sub {});
    my $t1 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok(@events >= 1, "auto_reconnect=0 watch received events");

    # Cancel and verify
    my $cancel_done = 0;
    $watch->cancel(sub { $cancel_done = 1; EV::break });
    my $t2 = EV::timer(3, 0, sub { EV::break });
    EV::run;

    ok($cancel_done, 'auto_reconnect=0 watch cancelled');
}

# Test 5-9: Watch with auto_reconnect => 1 (default) receives events
{
    my $key = "$prefix/with-reconnect";
    my @events;
    my $watch = $client->watch($key, sub {
        my ($resp, $err) = @_;
        return if $err;
        if ($resp->{events} && @{$resp->{events}}) {
            push @events, @{$resp->{events}};
            EV::break if @events >= 3;
        }
    });

    ok(defined $watch, 'watch with default auto_reconnect created');

    # Send multiple events to verify streaming works
    for my $i (1..3) {
        $client->put($key, "value-$i", sub {});
    }
    my $t3 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    cmp_ok(scalar @events, '>=', 1, "default watch received events");

    # Verify events have expected structure
    my $ev = $events[0];
    ok($ev->{kv}, 'event has kv field');
    is($ev->{kv}{key}, $key, 'event key matches watched key');
    is($ev->{type}, 'PUT', 'event type is PUT');

    my $cancel_done = 0;
    $watch->cancel(sub { $cancel_done = 1; EV::break });
    my $t4 = EV::timer(3, 0, sub { EV::break });
    EV::run;
}

# Test 10-11: Watch with auto_reconnect=0 on prefix key
{
    my $key = "$prefix/prefix-";
    my @events;
    my $watch = $client->watch($key, {
        auto_reconnect => 0,
        prefix => 1,
    }, sub {
        my ($resp, $err) = @_;
        return if $err;
        if ($resp->{events} && @{$resp->{events}}) {
            push @events, @{$resp->{events}};
            EV::break if @events >= 2;
        }
    });

    ok(defined $watch, 'prefix watch with auto_reconnect=0 created');

    # Put to two different subkeys
    $client->put("$prefix/prefix-a", "a", sub {});
    $client->put("$prefix/prefix-b", "b", sub {});
    my $t5 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    cmp_ok(scalar @events, '>=', 2, "prefix watch received events from multiple keys");

    my $cancel_done = 0;
    $watch->cancel(sub { $cancel_done = 1; EV::break });
    my $t6 = EV::timer(3, 0, sub { EV::break });
    EV::run;
}

# Cleanup
$client->delete("$prefix/", { prefix => 1 }, sub {
    ok(!$_[1], 'cleanup succeeded');
    EV::break;
});
my $t_cleanup = EV::timer(5, 0, sub { EV::break });
EV::run;

done_testing();
