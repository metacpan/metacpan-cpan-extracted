#!/usr/bin/env perl
# A watch resumes delivery after its connection drops: SIGSTOP on etcd breaks
# the stream by keepalive timeout, SIGCONT lets the reconnect succeed
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

# Only an etcd the caller names by PID gets frozen
my $etcd_pid = $ENV{ETCD_TEST_PID};
unless ($etcd_pid) {
    plan skip_all => 'set ETCD_TEST_PID to the PID of a local etcd to run this test';
}
unless (kill 0, $etcd_pid) {
    plan skip_all => "etcd PID $etcd_pid not running";
}

my $available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => ['127.0.0.1:2379'], timeout => 2);
    $c->status(sub { $available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};
plan skip_all => 'etcd not reachable' unless $available;

my $client = EV::Etcd->new(
    endpoints   => ['127.0.0.1:2379'],
    max_retries => 5,
    keepalive_time => 5,
    keepalive_timeout => 1,
);
my $key = "/test_reconnect_drop_$$";

sub wait_for {
    my ($condition, $seconds) = @_;
    my $poll = EV::timer(0.05, 0.05, sub { EV::break if $condition->() });
    my $guard = EV::timer($seconds, 0, sub { EV::break });
    EV::run;
}

my @events;
my $errors  = 0;
my $created = 0;
my $watch = $client->watch($key, { progress_notify => 1 }, sub {
    my ($resp, $err) = @_;
    if ($err) { $errors++; return; }
    $created++ if $resp->{created};
    push @events, @{$resp->{events} || []};
});
ok($watch, 'watch created');

# A put that lands before the watch is registered (created=1) is never delivered
wait_for(sub { $created }, 5);
ok($created, 'watch registered server-side');

my $pre_count = @events;
my $put_done;
$client->put($key, "before", sub { $put_done = 1 });
wait_for(sub { $put_done && @events > $pre_count }, 5);
ok(@events > $pre_count, 'event delivered before drop');

# Long enough for gRPC keepalive to close the stalled stream
note("SIGSTOP etcd pid=$etcd_pid");
kill 'STOP', $etcd_pid;
wait_for(sub { 0 }, 8);

note("SIGCONT etcd pid=$etcd_pid");
kill 'CONT', $etcd_pid;

# Give the reconnect machinery time to backoff + re-establish
wait_for(sub { $created >= 2 || $errors }, 10);

cmp_ok($created, '>=', 2, 'watch was recreated after the stalled connection closed');
is($errors, 0, 'watch reconnects without a terminal error');

my $mid_count = @events;
$put_done = 0;
$client->put($key, "after", sub { $put_done = 1 });
wait_for(sub { $put_done && @events > $mid_count }, 5);

ok(@events > $mid_count, 'event delivered after auto-reconnect');

$watch->cancel(sub {});
my $deleted;
$client->delete($key, sub { $deleted = 1 });
wait_for(sub { $deleted }, 2);

done_testing();
