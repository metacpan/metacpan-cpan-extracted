# Submitting with a `unique` key works end-to-end and is observable
# via get_status_unique. Regression coverage that the unique field
# encodes correctly into the SUBMIT_JOB body.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $cli  = EV::Gearman->new(host => $host, port => $port);
my $func = "uniq_test_$$";
my $unique = "k-$$-".time;

# 1. Submit a background job with a unique key — handle returned.
my ($handle, $err);
$cli->submit_job_bg($func, "payload", { unique => $unique }, sub {
    ($handle, $err) = @_; EV::break;
});
my $g = EV::timer 5, 0, sub { fail "submit timeout"; EV::break };
EV::run;
ok defined $handle, "got handle: ".($handle // 'undef');
is $err, undef, 'no error on bg submit with unique';

# 2. get_status_unique reports known=1 for our key.
my $info;
$cli->get_status_unique($unique, sub { $info = $_[0]; EV::break });
$g = EV::timer 5, 0, sub { fail "status timeout"; EV::break };
EV::run;
is ref($info), 'HASH', 'status hashref returned';
is $info->{unique}, $unique, 'unique key round-trips';
is $info->{known}, 1, 'job is known';
is $info->{running}, 0, 'not yet running (no worker)';

# 3. submit_job (foreground) with unique to a worker that completes —
#    worker sees the job and returns the right payload.
my $wkr = EV::Gearman->new(host => $host, port => $port);
my $seen_workload;
$wkr->register_function($func => sub {
    $seen_workload = $_[0]->workload;
    return "ok";
});
$wkr->work;

my ($r2, $e2);
$cli->submit_job($func, "fg-with-uniq", { unique => "fg-$$" }, sub {
    ($r2, $e2) = @_; EV::break;
});
$g = EV::timer 5, 0, sub { fail "fg uniq timeout"; EV::break };
EV::run;
is $r2, 'ok', 'foreground submit with unique completed';
is $seen_workload, 'fg-with-uniq', 'worker received the workload';

done_testing;
