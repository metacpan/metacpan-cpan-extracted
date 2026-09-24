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

plan tests => 11;

{
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
    );
    ok($client, 'client created with default retry settings');

    my $works = 0;
    $client->status(sub {
        my ($resp, $err) = @_;
        $works = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($works, 'client with default retries works');
}

{
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        max_retries => 10,
    );
    ok($client, 'client created with custom retry settings');

    my $works = 0;
    $client->status(sub {
        my ($resp, $err) = @_;
        $works = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($works, 'client with custom retries works');
}

{
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        max_retries => 0,
    );
    ok($client, 'client created with max_retries=0');

    my $works = 0;
    $client->status(sub {
        my ($resp, $err) = @_;
        $works = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($works, 'client with no retries works');
}

{
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        max_retries => 3,
    );

    my $prefix = "/test-retry-$$-" . time();
    my $watch_active = 0;
    my $events = 0;

    my $watch = $client->watch("$prefix/key", { auto_reconnect => 1 }, sub {
        my ($resp, $err) = @_;
        return if $err;
        $watch_active = 1;
        $events++ if $resp->{events} && @{$resp->{events}};
    });

    ok($watch, 'watch created with auto_reconnect');

    my $put_done = 0;
    $client->put("$prefix/key", "value", sub {
        $put_done = 1;
    });

    my $check;
    $check = EV::timer(0.1, 0.1, sub {
        EV::break if $events > 0 || !$watch_active;
    });
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($events > 0, 'watch with auto_reconnect received events');

    $watch->cancel(sub { EV::break });
    EV::run(EV::RUN_ONCE);

    $client->delete("$prefix/", { prefix => 1 }, sub { EV::break });
    EV::run;
}

{
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
    );

    my $prefix = "/test-retry2-$$-" . time();
    my $events = 0;
    my $put_sent = 0;

    my $watch = $client->watch("$prefix/key", { auto_reconnect => 0 }, sub {
        my ($resp, $err) = @_;
        return if $err;
        # A put committed before the watch is registered (created=1) is missed
        if ($resp->{created} && !$put_sent) {
            $put_sent = 1;
            $client->put("$prefix/key", "value", sub {});
            return;
        }
        $events++ if $resp->{events} && @{$resp->{events}};
    });

    ok($watch, 'watch created with auto_reconnect disabled');

    my $check;
    $check = EV::timer(0.1, 0.1, sub {
        EV::break if $events > 0;
    });
    my $timeout = EV::timer(3, 0, sub { EV::break });
    EV::run;

    ok($events > 0, 'watch without auto_reconnect received events');

    $watch->cancel(sub { EV::break });
    EV::run(EV::RUN_ONCE);

    $client->delete("$prefix/", { prefix => 1 }, sub { EV::break });
    EV::run;
}

{
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:29999'],
        timeout => 1,
        max_retries => 0,
    );

    my $retryable_set = 0;
    $client->get('/test', sub {
        my ($resp, $err) = @_;
        if ($err && ref($err) eq 'HASH') {
            $retryable_set = exists $err->{retryable};
        }
        EV::break;
    });

    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;

    ok($retryable_set, 'error contains retryable flag');
}

done_testing();
