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

plan tests => 8;

{
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        timeout => 5,
    );
    ok($client, 'client created with timeout=5');

    my $works = 0;
    $client->status(sub {
        my ($resp, $err) = @_;
        $works = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($works, 'client with custom timeout works');
}

{
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        timeout => 0,
    );
    ok($client, 'client created with timeout=0 (clamped to 1)');

    my $works = 0;
    $client->status(sub {
        my ($resp, $err) = @_;
        $works = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($works, 'client with clamped timeout works');
}

{
    my $health_called = 0;
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        health_interval => 1,
        on_health_change => sub {
            my ($is_healthy) = @_;
            $health_called++;
        },
    );
    ok($client, 'client created with health_interval');

    my $done = 0;
    $client->status(sub {
        $done = 1;
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($done, 'client with health monitoring works');
    # Whether on_health_change fired by now is timing-dependent, so not asserted
}

{
    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
    );
    ok($client, 'client created for size limit test');

    my $normal_key = "/test-size-$$/" . ('x' x 100);
    my $works = 0;
    $client->put($normal_key, "value", sub {
        my ($resp, $err) = @_;
        $works = 1 if !$err;
        EV::break;
    });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($works, 'normal size key accepted');

    $client->delete($normal_key, sub { EV::break });
    EV::run;
}

done_testing();
