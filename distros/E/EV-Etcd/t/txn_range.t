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

plan tests => 15;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

my $prefix = "/test-txn-range-$$-" . time();

my $setup_done = 0;
for my $i (1..3) {
    $client->put("$prefix/key$i", "val$i", sub {
        $setup_done++;
        EV::break if $setup_done == 3;
    });
}
my $t0 = EV::timer(5, 0, sub { fail('setup timeout'); EV::break });
EV::run;

$client->txn(
    compare => [],
    success => [
        { request_range => { key => "$prefix/key1" } }
    ],
    failure => [],
    sub {
        my ($resp, $err) = @_;
        ok(!$err, 'txn with request_range succeeded');
        ok($resp->{succeeded}, 'empty compare always succeeds');
        ok($resp->{responses} && @{$resp->{responses}}, 'txn has responses');
        my $range_resp = $resp->{responses}[0]{response_range};
        ok($range_resp && $range_resp->{kvs} && @{$range_resp->{kvs}},
            'response_range has kvs');
        is($range_resp->{kvs}[0]{value}, 'val1',
            'request_range returned correct value');
        EV::break;
    }
);
my $t1 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

# Prefix scan: range_end is the key with its last byte incremented
my $range_key = "$prefix/";
my $range_end = $range_key;
substr($range_end, -1, 1) = chr(ord(substr($range_end, -1, 1)) + 1);

$client->txn(
    compare => [],
    success => [
        { request_range => { key => $range_key, range_end => $range_end } }
    ],
    failure => [],
    sub {
        my ($resp, $err) = @_;
        ok(!$err, 'txn with prefix range succeeded');
        my $range_resp = $resp->{responses}[0]{response_range};
        ok($range_resp, 'got response_range');
        cmp_ok(scalar(@{$range_resp->{kvs}}), '>=', 3,
            'prefix range returned at least 3 keys');
        diag("Range returned " . scalar(@{$range_resp->{kvs}}) . " keys");
        EV::break;
    }
);
my $t2 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$client->txn(
    compare => [
        { key => "$prefix/key1", target => 'value', value => 'nonexistent' }
    ],
    success => [],
    failure => [
        { request_range => { key => "$prefix/key2" } }
    ],
    sub {
        my ($resp, $err) = @_;
        ok(!$err, 'txn with range in failure branch completed');
        ok(!$resp->{succeeded}, 'compare failed as expected');
        my $range_resp = $resp->{responses}[0]{response_range};
        ok($range_resp && $range_resp->{kvs} && @{$range_resp->{kvs}},
            'failure branch request_range returned results');
        is($range_resp->{kvs}[0]{value}, 'val2',
            'failure branch returned correct value');
        EV::break;
    }
);
my $t3 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$client->txn(
    compare => [],
    success => [
        { request_range => { key => "$prefix/key1" } },
        { request_put => { key => "$prefix/key4", value => "val4" } },
    ],
    failure => [],
    sub {
        my ($resp, $err) = @_;
        ok(!$err, 'mixed range+put txn succeeded');
        is(scalar(@{$resp->{responses}}), 2, 'got 2 responses for 2 ops');
        EV::break;
    }
);
my $t4 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

$client->delete("$prefix/", { prefix => 1 }, sub {
    ok(!$_[1], 'cleanup succeeded');
    EV::break;
});
my $t5 = EV::timer(5, 0, sub { fail('timeout'); EV::break });
EV::run;

done_testing();
