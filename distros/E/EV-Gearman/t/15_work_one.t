# work_one dispatches exactly one job and then leaves the worker loop —
# it must not grab a second job even when more are queued. A repeat
# call picks up where it left off.
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
my $wkr  = EV::Gearman->new(host => $host, port => $port);
my $func = "work_one_$$";

my @done;
$wkr->register_function($func => sub {
    push @done, $_[0]->workload;
    EV::break;            # stop the loop as soon as a job is dispatched
    return 'ok';
});

# Queue two jobs up front (background, so they sit in the server
# regardless of the worker).
my $created = 0;
$cli->submit_job_bg($func, 'a', sub { $created++ });
$cli->submit_job_bg($func, 'b', sub { $created++; EV::break if $created == 2 });
my $g = EV::timer 5, 0, sub { fail 'submit timeout'; EV::break };
EV::run;
is $created, 2, 'two jobs queued';

# First work_one: exactly one job.
$wkr->work_one;
$g = EV::timer 5, 0, sub { fail 'work_one #1 timeout'; EV::break };
EV::run;
is scalar(@done), 1, 'work_one dispatched exactly one job';

# Settle: the worker must not grab the second job on its own.
$g = EV::timer 0.3, 0, sub { EV::break };
EV::run;
is scalar(@done), 1, 'no further job grabbed after work_one returned';

# Second work_one: picks up the remaining job.
$wkr->work_one;
$g = EV::timer 5, 0, sub { fail 'work_one #2 timeout'; EV::break };
EV::run;
is scalar(@done), 2, 'second work_one dispatched the remaining job';
is_deeply [sort @done], ['a', 'b'], 'both jobs handled across two work_one calls';

done_testing;
