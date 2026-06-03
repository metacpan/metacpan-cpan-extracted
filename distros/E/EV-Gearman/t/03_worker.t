use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
unless ($probe) {
    plan skip_all => "no gearmand at $host:$port (set TEST_GEARMAN_HOST/PORT)";
}
close $probe;

sub run_with_timeout {
    my ($t, $why) = @_;
    my $w = EV::timer $t, 0, sub { fail("timeout: $why"); EV::break };
    EV::run;
}

my $cli = EV::Gearman->new(host => $host, port => $port);

# ===== async worker: completion deferred via timer =====
my $wkr_async = EV::Gearman->new(host => $host, port => $port);
my @pending_timers;
$wkr_async->register_function('test_async_'.$$ => { async => 1 }, sub {
    my $job = shift;
    push @pending_timers, EV::timer 0.05, 0, sub {
        $job->complete("async-done: " . $job->workload);
    };
});
$wkr_async->work;

my ($r, $e);
$cli->submit_job('test_async_'.$$, "hi", sub { ($r, $e) = @_; EV::break });
run_with_timeout 5, 'async worker';
is $r, "async-done: hi", 'async result delivered';

# ===== unique key with grab_unique =====
my $wkr_uniq = EV::Gearman->new(host => $host, port => $port, grab_unique => 1);
my $unique_seen;
$wkr_uniq->register_function('test_uniq_'.$$ => sub {
    my $job = shift;
    $unique_seen = $job->unique;
    return "ok";
});
$wkr_uniq->work;

($r, $e) = (undef, undef);
$cli->submit_job('test_uniq_'.$$, "wl", { unique => 'my-unique-key' }, sub {
    ($r, $e) = @_; EV::break
});
run_with_timeout 5, 'uniq worker';
is $r, "ok", 'unique worker returned ok';
is $unique_seen, 'my-unique-key', 'unique key visible to worker';

# ===== work_one (single-shot) =====
my $wkr_one = EV::Gearman->new(host => $host, port => $port);
my $count = 0;
$wkr_one->register_function('test_one_'.$$ => sub {
    my $job = shift;
    $count++;
    return "n=$count";
});
$wkr_one->work_one;

($r, $e) = (undef, undef);
$cli->submit_job('test_one_'.$$, "x", sub { ($r, $e) = @_; EV::break });
run_with_timeout 5, 'work_one';
is $r, "n=1", 'work_one handled one job';

# After one, the worker should not auto-grab another. Submit a second
# and verify work_one does NOT take it (we'd need to issue work_one again).
my $second_done;
$cli->submit_job('test_one_'.$$, "y", sub { $second_done = 1; EV::break });
my $w = EV::timer 0.5, 0, sub { EV::break };
EV::run;
ok !$second_done, 'work_one not picking up further jobs without re-arming';
$wkr_one->work_one;
$w = EV::timer 5, 0, sub { fail "second work_one timeout"; EV::break };
EV::run;
ok $second_done, 'second work_one picked up the next job';

# ===== cant_do removes ability =====
$wkr_one->cant_do('test_one_'.$$);
# subsequent grabs should not see this function (would block forever);
# we'll just check the call doesn't throw
pass 'cant_do called';

# ===== reset_abilities =====
$wkr_one->reset_abilities;
pass 'reset_abilities called';

done_testing;
