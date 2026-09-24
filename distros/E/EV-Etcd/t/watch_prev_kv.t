#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';

BEGIN {
    eval { require EV };
    if ($@) {
        plan skip_all => 'EV module not available';
        exit;
    }
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

plan tests => 12;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

ok($client, 'client created');

my $prefix = "/test-watch-prevkv-$$-" . time();
my $test_key = "$prefix/key";

{
    my $put_ok = 0;
    $client->put($test_key, "initial-value", sub {
        my ($resp, $err) = @_;
        $put_ok = !$err;
        EV::break;
    });
    my $t1 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($put_ok, 'initial put succeeded');

    my @events;
    my $watch = $client->watch($test_key, { prev_kv => 1 }, sub {
        my ($resp, $err) = @_;
        return if $err;
        if ($resp->{events} && @{$resp->{events}}) {
            push @events, @{$resp->{events}};
            EV::break if @events >= 1;
        }
    });

    ok($watch, 'watch created with prev_kv option');

    # Give watch time to establish
    my $settle = EV::timer(0.1, 0, sub {
        $client->put($test_key, "updated-value", sub {});
    });

    my $timeout = EV::timer(3, 0, sub { EV::break });
    EV::run;

    ok(@events >= 1, 'received update event');

    if (@events >= 1) {
        my $event = $events[0];
        is($event->{type}, 'PUT', 'event type is PUT');
        is($event->{kv}{value}, 'updated-value', 'current value is correct');

        ok(exists $event->{prev_kv}, 'event has prev_kv field');
        if ($event->{prev_kv}) {
            is($event->{prev_kv}{value}, 'initial-value', 'prev_kv contains previous value');
            diag("prev_kv test: previous='$event->{prev_kv}{value}', current='$event->{kv}{value}'");
        } else {
            fail('prev_kv should contain previous value');
        }
    } else {
        fail('event type check') for 1..4;
    }

    $watch->cancel(sub { EV::break });
    EV::run(EV::RUN_ONCE);
}

{
    my $delete_key = "$prefix/delete-test";
    $client->put($delete_key, "value-to-delete", sub { EV::break });
    my $t2 = EV::timer(5, 0, sub { EV::break });
    EV::run;

    my @events;
    my $watch = $client->watch($delete_key, { prev_kv => 1 }, sub {
        my ($resp, $err) = @_;
        return if $err;
        if ($resp->{events} && @{$resp->{events}}) {
            push @events, @{$resp->{events}};
            EV::break if @events >= 1;
        }
    });

    ok($watch, 'delete watch created with prev_kv');

    # Give watch time to establish
    my $settle = EV::timer(0.1, 0, sub {
        $client->delete($delete_key, sub {});
    });

    my $timeout = EV::timer(3, 0, sub { EV::break });
    EV::run;

    ok(@events >= 1, 'received delete event');

    if (@events >= 1) {
        my $event = $events[0];
        is($event->{type}, 'DELETE', 'event type is DELETE');

        if ($event->{prev_kv}) {
            is($event->{prev_kv}{value}, 'value-to-delete', 'prev_kv contains deleted value');
            diag("delete prev_kv: had value '$event->{prev_kv}{value}'");
        } else {
            fail('prev_kv should contain deleted value');
        }
    } else {
        fail('event type check') for 1..2;
    }

    $watch->cancel(sub { EV::break });
    EV::run(EV::RUN_ONCE);
}

$client->delete("$prefix/", { prefix => 1 }, sub { EV::break });
my $t_cleanup = EV::timer(5, 0, sub { EV::break });
EV::run;

done_testing();
