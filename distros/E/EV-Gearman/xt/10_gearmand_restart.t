# gearmand restart: kill the server with jobs in flight, restart it,
# verify the worker reconnects, re-registers its abilities, and
# resumes processing new submissions.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp qw(tempdir);
use EV;
use EV::Gearman;

my $gearmand;
for my $dir (split(/:/, $ENV{PATH}), '/usr/sbin', '/usr/local/sbin') {
    next unless $dir;
    my $exe = "$dir/gearmand";
    if (-f $exe && -x $exe) { $gearmand = $exe; last }
}
plan skip_all => 'gearmand not found' unless $gearmand;

my $port = 19000 + ($$ % 1000);
diag "using gearmand=$gearmand port=$port";

sub spawn_gearmand {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close STDIN; close STDOUT; close STDERR;
        exec $gearmand, '--port', $port, '--listen', '127.0.0.1', '-t', 1,
                        '--job-handle-prefix=H:gm';
        exit 1;
    }
    for (1..30) {
        my $s = IO::Socket::INET->new(
            PeerAddr => "127.0.0.1:$port", Timeout => 1,
        );
        if ($s) { close $s; return $pid }
        select undef, undef, undef, 0.1;
    }
    kill 'KILL', $pid; waitpid $pid, 0;
    return;
}

my $gmpid = spawn_gearmand();
plan skip_all => 'could not spawn gearmand' unless $gmpid;

my $func = "restart_$$";
my $cli = EV::Gearman->new(host => '127.0.0.1', port => $port);
my $wkr = EV::Gearman->new(
    host             => '127.0.0.1',
    port             => $port,
    reconnect        => 1,
    reconnect_delay  => 100,
);
$wkr->register_function($func => sub { uc $_[0]->workload });
$wkr->work;

# Pre-restart: one round-trip to confirm both ends are healthy.
my ($r1, $e1);
$cli->submit_job($func, "before", sub { ($r1, $e1) = @_; EV::break });
my $g = EV::timer 5, 0, sub { fail "pre-restart timeout"; EV::break };
EV::run;
is $r1, 'BEFORE', 'job worked before restart';

# Kill gearmand.
kill 'TERM', $gmpid;
waitpid $gmpid, 0;

# Re-spawn it.
$gmpid = spawn_gearmand();
ok $gmpid, 'gearmand re-spawned';

# After reconnect the worker re-registers automatically; verify by
# submitting another job through a fresh client (the old $cli is in
# disconnected state).
my $cli2 = EV::Gearman->new(host => '127.0.0.1', port => $port);
my ($r2, $e2);
# Give the worker a beat to reconnect (reconnect_delay=100ms).
my $kick = EV::timer 0.5, 0, sub {
    $cli2->submit_job($func, "after", sub { ($r2, $e2) = @_; EV::break });
};
$g = EV::timer 10, 0, sub { fail "post-restart timeout"; EV::break };
EV::run;
is $r2, 'AFTER', 'worker re-registered ability + handled new job';
is $e2, undef,   'no error after restart';

undef $cli; undef $cli2; undef $wkr;
kill 'TERM', $gmpid; waitpid $gmpid, 0;
done_testing;
