#!/usr/bin/env perl
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;

# A watch canceled for compaction reports compact_revision on the error

BEGIN {
    eval { require EV };
    plan skip_all => 'EV required' if $@;
}

use EV;
use EV::Etcd;

my $etcd_available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $etcd_available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};

plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $etcd_available;
plan skip_all => 'compacts etcd history: set EV_ETCD_TEST_ETCD=1 for an etcd that exists for testing'
    unless $ENV{EV_ETCD_TEST_ETCD};

plan tests => 6;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

ok($client, 'client created');

my $test_key = "/test_watch_compact_$$";

my $rev;
for my $i (1..3) {
    $client->put($test_key, "value_$i", sub {
        my ($resp, $err) = @_;
        $rev = $resp->{header}{revision} if !$err;
        EV::break;
    });
    EV::run;
}
ok($rev, "puts succeeded (rev $rev)");

my $compact_err;
$client->compact($rev, sub {
    my ($resp, $err) = @_;
    $compact_err = $err;
    EV::break;
});
EV::run;
ok(!$compact_err, 'compact succeeded');

my $cancel_err;
$client->watch($test_key, {
    start_revision => 1,
}, sub {
    my ($resp, $err) = @_;
    if ($err) { $cancel_err = $err; EV::break; }
});
my $timer = EV::timer(5, 0, sub { EV::break });
EV::run;

ok($cancel_err, 'compacted watch delivered an error');
is($cancel_err->{source}, 'watch', 'error source is watch');
is($cancel_err->{compact_revision}, $rev, "compact_revision is $rev");

diag("message: $cancel_err->{message}") if $cancel_err;

$client->delete($test_key, sub { EV::break });
my $cleanup = EV::timer(5, 0, sub { EV::break });
EV::run;

done_testing();
