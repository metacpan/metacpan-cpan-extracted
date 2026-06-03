# submit_job_epoch schedules a background job for a future wall-clock
# time. We schedule far enough out that it won't run during the test,
# then confirm the server accepted it (a handle came back) and reports
# it as a known, not-yet-running job.
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
my $func = "epoch_$$";

# 1) Schedule for an hour out; expect a JOB_CREATED handle back.
my ($handle, $err);
$cli->submit_job_epoch($func, 'later', time() + 3600, sub {
    ($handle, $err) = @_; EV::break;
});
my $g = EV::timer 5, 0, sub { fail 'epoch submit timeout'; EV::break };
EV::run;
is $err, undef, 'no error scheduling an epoch job';
like $handle, qr/\S/, "got a job handle ($handle)";

# 2) The scheduled job should be known to the server but not running
#    (no worker, and its time hasn't come).
my $info;
$cli->get_status($handle, sub { $info = $_[0]; EV::break });
$g = EV::timer 5, 0, sub { fail 'get_status timeout'; EV::break };
EV::run;
is ref($info), 'HASH', 'status hashref returned';
is $info->{known},   1, 'scheduled job is known to the server';
is $info->{running}, 0, 'scheduled job is not running yet';

# 3) The unique opt is accepted on the epoch path too.
my ($h2, $e2);
$cli->submit_job_epoch($func, 'keyed', time() + 3600,
    { unique => "epoch-$$" }, sub { ($h2, $e2) = @_; EV::break });
$g = EV::timer 5, 0, sub { fail 'epoch+unique submit timeout'; EV::break };
EV::run;
is $e2, undef, 'epoch job with unique key accepted';
like $h2, qr/\S/, 'epoch job with unique key returned a handle';

done_testing;
