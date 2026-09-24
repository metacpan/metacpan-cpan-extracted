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
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $etcd_available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};
plan skip_all => 'etcd not available on 127.0.0.1:2379' unless $etcd_available;

# Pins a UAF: a handle held past its client-side cleanup must stay callable

my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);

my $key = "/test_cancel_lifetime_$$";
my $watch = $client->watch($key, sub { });
ok($watch, 'watch handle created');

my $cancel_done = 0;
$watch->cancel(sub { $cancel_done = 1; EV::break });
my $t1 = EV::timer(2, 0, sub { EV::break });
EV::run;
ok($cancel_done, 'first cancel callback fired');

# Let the cancelled RECV completion run cleanup_watch before cancelling again
my $t2 = EV::timer(0.2, 0, sub { EV::break });
EV::run;

my $second = 0;
$watch->cancel(sub { $second = 1; EV::break });
my $t3 = EV::timer(2, 0, sub { EV::break });
EV::run;
ok($second, 'second cancel on already-cleaned handle is safe');

my $lease_id;
$client->lease_grant(10, sub { $lease_id = $_[0]->{id}; EV::break });
my $tg = EV::timer(3, 0, sub { EV::break });
EV::run;
ok($lease_id, 'lease granted');

my $ka = $client->lease_keepalive($lease_id, sub { });
ok($ka, 'keepalive handle created');

my $ka_done = 0;
$ka->cancel(sub { $ka_done = 1; EV::break });
my $tk = EV::timer(2, 0, sub { EV::break });
EV::run;
ok($ka_done, 'keepalive cancel fired');

my $ti = EV::timer(0.2, 0, sub { EV::break });
EV::run;

my $ka_second = 0;
$ka->cancel(sub { $ka_second = 1; EV::break });
my $tk2 = EV::timer(2, 0, sub { EV::break });
EV::run;
ok($ka_second, 'second keepalive cancel is safe');

my $election_name = "test-cancel-lifetime-$$";
my $observe = $client->election_observe($election_name, sub { });
ok($observe, 'observe handle created');

my $obs_done = 0;
$observe->cancel(sub { $obs_done = 1; EV::break });
my $to1 = EV::timer(2, 0, sub { EV::break });
EV::run;
ok($obs_done, 'observe cancel fired');

my $tobs = EV::timer(0.2, 0, sub { EV::break });
EV::run;

my $obs_second = 0;
$observe->cancel(sub { $obs_second = 1; EV::break });
my $to2 = EV::timer(2, 0, sub { EV::break });
EV::run;
ok($obs_second, 'second observe cancel is safe');

$client->lease_revoke($lease_id, sub { EV::break });
my $tr = EV::timer(2, 0, sub { EV::break });
EV::run;

$client->delete($key, sub { EV::break });
my $td = EV::timer(2, 0, sub { EV::break });
EV::run;

done_testing();
