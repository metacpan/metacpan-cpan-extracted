#!/usr/bin/env perl
# Drop the gRPC connection mid-watch and verify auto-reconnect resumes
# delivering events. We freeze etcd with SIGSTOP so the existing stream
# breaks (gRPC keepalive timeout) and unfreeze to let the reconnect succeed.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

# Find a running etcd we can SIGSTOP. We only run when we own the process.
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
);
my $key = "/test_reconnect_drop_$$";

my @events;
my $errors  = 0;
my $created = 0;
my $watch = $client->watch($key, { progress_notify => 1 }, sub {
    my ($resp, $err) = @_;
    if ($err) { $errors++; return; }
    $created ||= $resp->{created};
    push @events, @{$resp->{events} || []};
});
ok($watch, 'watch created');

# Wait for the watch's first server response (created=1) before issuing puts
my $created_check = EV::timer(0.05, 0.05, sub { EV::break if $created });
my $created_bail  = EV::timer(5, 0, sub { EV::break });
EV::run;
ok($created, 'watch registered server-side');

# Pre-drop: confirm normal delivery
my $pre_count = @events;
$client->put($key, "before", sub { EV::break });
my $t1 = EV::timer(2, 0, sub { EV::break });
EV::run;
ok(@events > $pre_count, 'event delivered before drop');

# Freeze etcd → server-side stream stalls; gRPC keepalive eventually closes it
note("SIGSTOP etcd pid=$etcd_pid");
kill 'STOP', $etcd_pid;
my $stop_timer = EV::timer(8, 0, sub { EV::break });
EV::run;

note("SIGCONT etcd pid=$etcd_pid");
kill 'CONT', $etcd_pid;

# Give the reconnect machinery time to backoff + re-establish
my $recover_timer = EV::timer(10, 0, sub { EV::break });
EV::run;

my $mid_count = @events;
$client->put($key, "after", sub { EV::break });
my $t2 = EV::timer(5, 0, sub { EV::break });
EV::run;

ok(@events > $mid_count, 'event delivered after auto-reconnect');

# Cleanup
$watch->cancel(sub { EV::break });
my $tc = EV::timer(2, 0, sub { EV::break });
EV::run;
$client->delete($key, sub { EV::break });
my $td = EV::timer(2, 0, sub { EV::break });
EV::run;

done_testing();
