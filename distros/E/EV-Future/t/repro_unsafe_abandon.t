use strict;
use warnings;
use Test::More;
use EV;
use EV::Future;

# An uncaught exception from an unsafe-mode task unwinds past our dispatch
# frame. Two things used to go wrong:
#
#   * parallel_limit re-dispatches from plimit_task_done (i.e. from the event
#     loop), and that frame installed a stack-local is_freed with no guard on
#     it. An exception there left ctx->is_freed_ptr pointing at a dead stack
#     slot; a later completion wrote through it (stack-use-after-return), and
#     ctx->running stayed 1, wedging the remaining tasks.
#
#   * The context stayed live with settled/remaining untouched, so a pending
#     async task could still fire final_cb long after the exception had been
#     reported. Safe mode guarantees the opposite.
#
# The contract now: an escaping unsafe-mode exception abandons the operation.
# final_cb never fires, no further task is dispatched, and nothing writes to
# the unwound frame. (The context still leaks in unsafe mode; that is
# documented.)

# Burn stack so a dangling stack pointer would land on live memory.
sub churn {
    my $n = shift;
    my @buf = (1) x 256;
    return $n ? churn($n - 1) : @buf;
}

# EV reports uncaught callback exceptions via warn; keep test output clean.
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub run_loop {
    my $bail = EV::timer 1.0, 0, sub { EV::break };
    eval { EV::run };
    return $@;
}

subtest 'parallel_limit unsafe: exception from a re-dispatched task' => sub {
    our @w;
    my $final = 0;

    # limit 2: t1/t2 go out in the XSUB burst, t3 is dispatched from t1's
    # completion (event loop). t3 completes then dies, so t2's later
    # completion drives remaining to 0 inside plimit_cleanup.
    parallel_limit([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
        sub { my $d = shift; push @w, EV::timer 0.05, 0, sub { $d->() } },
        sub { my $d = shift; $d->(); die "boom\n" },
    ], 2, sub { $final++ }, 1);

    my $err = run_loop();
    churn(40);

    ok(!$err, 'EV::run completed without error') or diag $err;
    is($final, 0, 'final_cb not called after unsafe exception');
    @w = ();
};

subtest 'parallel_limit unsafe: no further dispatch after exception' => sub {
    our @w;
    my ($t4_ran, $final) = (0, 0);

    parallel_limit([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
        sub { my $d = shift; push @w, EV::timer 0.30, 0, sub { $d->() } },
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() }; die "boom\n" },
        sub { my $d = shift; $t4_ran++; $d->() },
    ], 2, sub { $final++ }, 1);

    my $err = run_loop();
    churn(40);

    ok(!$err, 'EV::run completed without error') or diag $err;
    is($t4_ran, 0, 'no task dispatched after the exception');
    is($final, 0, 'final_cb not called');
    @w = ();
};

subtest 'series unsafe: exception from an event-loop dispatch abandons series' => sub {
    our @w;
    my ($t3_ran, $final) = (0, 0);

    series([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() }; die "boom\n" },
        sub { my $d = shift; $t3_ran++; $d->() },
    ], sub { $final++ }, 1);

    my $err = run_loop();
    churn(40);

    ok(!$err, 'EV::run completed without error') or diag $err;
    is($t3_ran, 0, 'series does not continue past the failed task');
    is($final, 0, 'final_cb not called');
    @w = ();
};

subtest 'parallel unsafe: late completion does not fire final_cb' => sub {
    our @w;
    my $final = 0;

    eval {
        parallel([
            sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
            sub { my $d = shift; $d->(); die "boom\n" },
        ], sub { $final++ }, 1);
    };
    is($@, "boom\n", 'exception propagated to caller');

    my $err = run_loop();
    churn(40);

    ok(!$err, 'EV::run completed without error') or diag $err;
    is($final, 0, 'final_cb not called by the late completion');
    @w = ();
};

subtest 'race unsafe: late winner does not fire final_cb' => sub {
    our @w;
    my $final = 0;

    eval {
        race([
            sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->("late") } },
            sub { die "boom\n" },
        ], sub { $final++ }, 1);
    };
    is($@, "boom\n", 'exception propagated to caller');

    my $err = run_loop();
    churn(40);

    ok(!$err, 'EV::run completed without error') or diag $err;
    is($final, 0, 'final_cb not called by the late winner');
    @w = ();
};

# An abandoned operation is frozen, not finished: nothing will ever advance it,
# and in unsafe mode its context is deliberately leaked because the unwind
# cannot run cleanup. A handle held over it is the only thing that can still
# reach that context, and cancel() is the documented way to reclaim it.
#
# The assertions below pin the observable half of that contract: stale non-zero
# counts while abandoned, zero after cancel, and final_cb firing only for
# cancel(1). The reclaim of the memory itself is deliberately not asserted here,
# because no leak checker can see it - the leaked context stays reachable
# through the shared done CV's payload pointer, which lives in a Perl SV arena,
# so valgrind reports it as still reachable rather than lost either way. It was
# measured instead by counting live allocations at exit: 20 abandonments leave
# 45 blocks from plimit_start alive without the cancel and 2 with it.
subtest 'cancel reclaims an abandoned operation' => sub {
    our @w;

    # limit 2: tasks 1 and 2 go out in the opening burst, so the handle is
    # assigned before task 3 is dispatched from the event loop and dies there.
    my ($final, $h) = (0);
    $h = parallel_limit([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
        sub { my $d = shift; push @w, EV::timer 0.50, 0, sub { $d->() } },
        sub { die "boom\n" },
        sub { my $d = shift; $d->() },
    ], 2, sub { $final++ }, 1);

    my $bail = EV::timer 0.1, 0, sub { EV::break };
    eval { EV::run };

    is($final, 0, 'final_cb did not fire after the abandonment');
    cmp_ok($h->pending, '>', 0, 'an abandoned operation still reports pending tasks');
    cmp_ok($h->active,  '>', 0, 'and still reports tasks in flight');

    $h->cancel;
    is($h->pending, 0, 'cancel released the abandoned context: pending is zero');
    is($h->active,  0, 'cancel released the abandoned context: active is zero');
    is($final, 0, 'a plain cancel still did not fire final_cb');

    # Same shape again, this time recovered with the firing form.
    my ($final2, $h2) = (0);
    $h2 = parallel_limit([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
        sub { my $d = shift; push @w, EV::timer 0.50, 0, sub { $d->() } },
        sub { die "boom\n" },
        sub { my $d = shift; $d->() },
    ], 2, sub { $final2++ }, 1);

    my $bail2 = EV::timer 0.1, 0, sub { EV::break };
    eval { EV::run };
    is($final2, 0, 'second operation abandoned too');

    $h2->cancel(1);
    is($final2, 1, 'cancel(1) fired final_cb once after the abandonment');
    is($h2->pending, 0, 'and released the context');
    @w = ();
};

subtest 'safe mode still completes normally' => sub {
    our @w;
    my $final = 0;

    # No exception: the guard must not abandon anything on a normal unwind.
    parallel_limit([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
        sub { my $d = shift; push @w, EV::timer 0.02, 0, sub { $d->() } },
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
    ], 2, sub { $final++; EV::break });

    my $err = run_loop();
    ok(!$err, 'EV::run completed without error') or diag $err;
    is($final, 1, 'final_cb fired exactly once');
    @w = ();
};

done_testing;
