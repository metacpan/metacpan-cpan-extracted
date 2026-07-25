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

# ===== cant_do withdraws the ability server-side =====
# Behavioural: with the function withdrawn on its only worker, a
# submitted job must stay queued undelivered; a second worker then
# proves the job was merely unclaimed, not lost. The worker keeps a
# second ability so it stays in the GRAB loop — otherwise even a
# broken CANT_DO would leave the job queued by accident.
{
    my $f      = 'test_cantdo_'.$$;
    my $f_keep = 'test_cantdo_keep_'.$$;
    my ($fired, $r, $e);
    my $w1;
    $w1 = EV::Gearman->new(
        host => $host, port => $port,
        on_connect => sub {
            $w1->cant_do($f);
            $cli->submit_job($f, 'payload', sub {
                $fired = 1; ($r, $e) = @_; EV::break;
            });
        },
    );
    $w1->register_function($f      => sub { return 'w1' });
    $w1->register_function($f_keep => sub { return 'keep' });
    $w1->work;

    my $settle = EV::timer 0.8, 0, sub { EV::break };
    EV::run;
    ok !$fired, 'cant_do: job not delivered to the withdrawn worker';

    my $w2 = EV::Gearman->new(host => $host, port => $port);
    $w2->register_function($f => sub { my $j = shift; return 'w2:' . $j->workload });
    $w2->work;
    run_with_timeout 5, 'drain after cant_do';
    ok $fired, 'cant_do: a fresh worker picked up the queued job';
    is $e, undef, 'cant_do: no error';
    is $r, 'w2:payload', 'cant_do: queued job completed on the second worker';
}

# ===== reset_abilities withdraws everything server-side =====
# Same behavioural shape: after reset_abilities (and re-registering an
# unrelated ability so the worker keeps grabbing), a job for the old
# function must stay queued until another worker serves it.
{
    my $f      = 'test_reset_'.$$;
    my $f_keep = 'test_reset_keep_'.$$;
    my ($fired, $r, $e);
    my $w1;
    $w1 = EV::Gearman->new(
        host => $host, port => $port,
        on_connect => sub {
            $w1->reset_abilities;
            $w1->register_function($f_keep => sub { return 'keep' });
            $w1->work;
            $cli->submit_job($f, 'payload', sub {
                $fired = 1; ($r, $e) = @_; EV::break;
            });
        },
    );
    $w1->register_function($f => sub { return 'w1' });
    $w1->work;

    my $settle = EV::timer 0.8, 0, sub { EV::break };
    EV::run;
    ok !$fired, 'reset_abilities: job not delivered to the reset worker';

    my $w2 = EV::Gearman->new(host => $host, port => $port);
    $w2->register_function($f => sub { my $j = shift; return 'w2:' . $j->workload });
    $w2->work;
    run_with_timeout 5, 'drain after reset_abilities';
    ok $fired, 'reset_abilities: a fresh worker picked up the queued job';
    is $e, undef, 'reset_abilities: no error';
    is $r, 'w2:payload', 'reset_abilities: queued job completed on the second worker';
}

# ===== can_do without a handler: work() must warn, not silently fail =====
# can_do() records the ability with no callback; dispatching such a
# job used to call_sv(NULL) under G_EVAL and answer a silent WORK_FAIL.
my @warns;
my $fails = 0;
{
    my $wkr_nocb = EV::Gearman->new(host => $host, port => $port);
    $wkr_nocb->can_do('test_nocb_'.$$);
    $wkr_nocb->work;

    local $SIG{__WARN__} = sub { push @warns, @_ };
    $cli->submit_job('test_nocb_'.$$, "wl1", sub { $fails++ if $_[1]; EV::break if $fails == 2 });
    $cli->submit_job('test_nocb_'.$$, "wl2", sub { $fails++ if $_[1]; EV::break if $fails == 2 });
    run_with_timeout 5, 'can_do without handler';
}
is $fails, 2, 'jobs for a handler-less function answered with WORK_FAIL';
my @nocb = grep { /no handler for function 'test_nocb_$$'/ } @warns;
is scalar(@nocb), 1, 'warns once per function, naming it';
like $nocb[0] || '', qr/register_function or grab_job/, 'warning suggests the fix';

# ===== grab_job must keep working for a can_do ability =====
my $wkr_grab = EV::Gearman->new(host => $host, port => $port);
$wkr_grab->can_do('test_grab_'.$$);
$wkr_grab->grab_job(sub {
    my $job = shift;
    $job->complete("grabbed: " . $job->workload);
});
($r, $e) = (undef, undef);
$cli->submit_job('test_grab_'.$$, "payload", sub { ($r, $e) = @_; EV::break });
run_with_timeout 5, 'grab_job with can_do';
is $r, "grabbed: payload", 'grab_job delivers jobs for a can_do ability';

done_testing;
