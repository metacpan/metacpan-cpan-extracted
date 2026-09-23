use strict;
use warnings;
use Config;
use POSIX ();
use Test::More;
use EV;
use EV::Telegram::TDLib;

plan skip_all => 'no fork on this platform' unless $Config::Config{d_fork};

my $id = EV::Telegram::TDLib::_create_client_id();
ok $id > 0, 'client created in the parent';

# the OO layer holds one loop ref per open client; take it by hand here,
# since this test drives the XS layer directly.
# Two, not one: only the first takes an actual ev_ref, so a fork handler
# that gave one back per client would leave the child's loop short, and
# with a single ref the arithmetic happens to come out right anyway
EV::Telegram::TDLib::_pump_ref();
EV::Telegram::TDLib::_pump_ref();

# deliberately never closed and the loop deliberately never run: a pending
# async across fork is the whole point, and closing would need the loop
# a local request so the reader queues a reply and raises the async;
# the parent never runs its loop, so the async stays pending across fork
EV::Telegram::TDLib::_send($id, '{"@type":"getOption","name":"version"}');
select undef, undef, undef, 0.3;

my $pid = fork;
defined $pid or die "fork: $!";
if (!$pid) {
    alarm 10;
    my $fired = 0;
    # the loop never ran in this process, so ev_now is from before the sleep
    # above: armed from it the timer was already due, fired on the first
    # iteration, and passed whether or not the loop was a ref short
    EV::now_update();
    my $t = EV::timer 0.2, 0, sub { $fired = 1 };
    # the inherited pump ref and a pending async firing td_drain must not
    # hang a child that runs the loop for its own work -- nor make the loop
    # fall straight through, which is what an over-generous unref does
    EV::run;
    POSIX::_exit($fired ? 0 : 3);
}

my $status;
eval {
    local $SIG{ALRM} = sub { die "waitpid timed out\n" };
    alarm 20;
    waitpid $pid, 0;
    $status = $?;
    alarm 0;
};
if ($@) {
    kill 9, $pid;
    waitpid $pid, 0;
    fail "child running EV::run did not exit within the bound: $@";
}
else {
    is $status & 127, 0, 'the child was not killed by a signal';
    is $status >> 8, 0, 'the child running EV::run exited cleanly';
}

EV::Telegram::TDLib::_pump_unref();

# this process has had a client since the top of the file, so a forked child
# must still be refused; the clean-fork case needs a parent that never made
# one and lives in t/22_fork_clean.t
SKIP: {
    skip 'no fork on this platform', 1 unless $Config::Config{d_fork};
    my $dirty = fork;
    defined $dirty or die "fork: $!";
    if (!$dirty) {
        my $ok = eval {
            EV::Telegram::TDLib::_send($id, '{"@type":"getOption","name":"version"}');
            1;
        };
        POSIX::_exit($ok ? 1 : 0);
    }
    waitpid $dirty, 0;
    is $? >> 8, 0, 'a child forked with a client already made is still refused';
}

# This file drives a raw client id, so nothing closes it: leaving it
# materialised at exit is the crash window TDLib opens once teardown has
# begun (no client teardown, and the scheduler thread is detached rather
# than joined). Closing it costs nothing the test depends on -- the fork
# behaviour above has already been asserted.
{
    my $shut = 0;
    EV::Telegram::TDLib::_set_dispatch(sub {
        my (undef, $json) = @_;
        $shut = 1 if $json =~ /authorizationStateClosed/;
        EV::break if $shut;
    });
    EV::Telegram::TDLib::_send($id, '{"@type":"close"}');
    my $late = 0;
    my $w = EV::timer 15, 0, sub { $late = 1; EV::break };
    EV::run(EV::RUN_ONCE) while !$shut && !$late;
    $w->stop;
    EV::Telegram::TDLib::_set_dispatch(\&EV::Telegram::TDLib::dispatch_raw);
    ok $shut, 'the raw client closed before exit';
}

done_testing;
