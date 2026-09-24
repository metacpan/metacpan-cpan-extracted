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

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

my $lock_name = "test-lock-$$-" . time();
my $lease_id;
my $lock_key;

$client->lease_grant(30, sub {
    my ($resp, $err) = @_;
    ok(!$err, 'lease_grant succeeded');
    ok($resp->{id}, 'got lease id');
    $lease_id = $resp->{id};
    EV::break;
});
my $t1 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

SKIP: {
    skip "no lease id", 6 unless $lease_id;

    $client->lock($lock_name, $lease_id, sub {
        my ($resp, $err) = @_;
        ok(!$err, 'lock succeeded');
        ok($resp->{key}, 'got lock key');
        $lock_key = $resp->{key};
        diag("Lock key: $lock_key") if $lock_key;
        EV::break;
    });
    my $t2 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
    EV::run;

    SKIP: {
        skip "no lock key", 4 unless $lock_key;

        $client->get($lock_key, sub {
            my ($resp, $err) = @_;
            ok(!$err, 'get lock key succeeded');
            is(scalar @{$resp->{kvs} || []}, 1, 'lock key exists');
            EV::break;
        });
        my $t3 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
        EV::run;

        $client->unlock($lock_key, sub {
            my ($resp, $err) = @_;
            ok(!$err, 'unlock succeeded');
            ok($resp->{header}, 'unlock response has header');
            EV::break;
        });
        my $t4 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
        EV::run;
    }
}

if ($lease_id) {
    $client->lease_revoke($lease_id, sub { EV::break });
    my $t5 = EV::timer(2, 0, sub { EV::break });
    EV::run;
}

done_testing();
