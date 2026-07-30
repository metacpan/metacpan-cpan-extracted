use strict;
use warnings;
use Test::More;
use EV;
use EV::Future;

subtest 'handle is returned in non-void context' => sub {
    our @w;
    my $h = parallel([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
    ], sub { });

    isa_ok($h, 'EV::Future::Handle');
    EV::run;
    @w = ();
};

subtest 'every primitive returns a handle' => sub {
    our @w;
    my $task = sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } };
    my $work = sub { my ($i, $d) = @_; push @w, EV::timer 0.01, 0, sub { $d->() } };

    isa_ok(parallel([$task], sub { }),                    'EV::Future::Handle', 'parallel');
    isa_ok(parallel_limit([$task], 1, sub { }),           'EV::Future::Handle', 'parallel_limit');
    isa_ok(series([$task], sub { }),                      'EV::Future::Handle', 'series');
    isa_ok(race([$task], sub { }),                        'EV::Future::Handle', 'race');
    isa_ok(parallel_map([1], $work, sub { }),             'EV::Future::Handle', 'parallel_map');
    isa_ok(parallel_map_limit([1], $work, 1, sub { }),    'EV::Future::Handle', 'parallel_map_limit');
    isa_ok(series_map([1], $work, sub { }),               'EV::Future::Handle', 'series_map');

    EV::run;
    @w = ();
};

subtest 'handle survives the operation completing' => sub {
    my $h = parallel([sub { shift->() }], sub { });
    isa_ok($h, 'EV::Future::Handle');
    # The operation completed synchronously; the handle must still be a valid
    # object that can be destroyed without crashing.
    undef $h;
    pass('handle destroyed after its operation finished');
};

subtest 'operation survives the handle being destroyed' => sub {
    our @w;
    my $final = 0;
    {
        my $h = parallel([
            sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
        ], sub { $final++; EV::break });
        isa_ok($h, 'EV::Future::Handle');
    }
    EV::run;
    is($final, 1, 'operation completed after the handle went away');
    @w = ();
};

subtest 'empty task list still yields a handle' => sub {
    my $final = 0;
    my $h = parallel([], sub { $final++ });
    isa_ok($h, 'EV::Future::Handle');
    is($final, 1, 'final_cb fired');
};

# The empty list is a separate early-return path in each of the four context
# shapes (parallel, series, parallel_limit and race's inline body), so each has
# to hand back a dead handle rather than undef on its own.
subtest 'every primitive yields a handle for an empty list' => sub {
    my $work = sub { my (undef, $d) = @_; $d->() };

    isa_ok(parallel([], sub { }),                  'EV::Future::Handle', 'parallel');
    isa_ok(parallel_limit([], 1, sub { }),         'EV::Future::Handle', 'parallel_limit');
    isa_ok(series([], sub { }),                    'EV::Future::Handle', 'series');
    isa_ok(race([], sub { }),                      'EV::Future::Handle', 'race');
    isa_ok(parallel_map([], $work, sub { }),       'EV::Future::Handle', 'parallel_map');
    isa_ok(parallel_map_limit([], $work, 1, sub { }), 'EV::Future::Handle', 'parallel_map_limit');
    isa_ok(series_map([], $work, sub { }),         'EV::Future::Handle', 'series_map');
};

# List context is non-void too, so it must yield exactly one handle: an
# implementation that tested for G_SCALAR rather than "not G_VOID" would
# return an empty list here.
subtest 'list context yields exactly one handle' => sub {
    our @w;
    my @r = parallel([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
    ], sub { });

    is(scalar @r, 1, 'exactly one value returned');
    isa_ok($r[0], 'EV::Future::Handle');
    EV::run;
    @w = ();
};

# A task that croaks unwinds straight through the primitive, so the handle
# allocated before dispatch is never handed to Perl. The exception must still
# reach the caller unchanged, and the abandoned cell must not be leaked; the
# leak half of that is what this file's valgrind gate checks.
subtest 'a croaking task propagates when a handle was requested' => sub {
    my $die = sub { die "boom\n" };
    my @cases = (
        [ 'parallel',       sub { parallel([$die], sub { }) } ],
        [ 'series',         sub { series([$die], sub { }) } ],
        [ 'parallel_limit', sub { parallel_limit([$die], 1, sub { }) } ],
        [ 'race',           sub { race([$die], sub { }) } ],
    );

    for my $case (@cases) {
        my ($name, $call) = @$case;
        my $h = 'unset';
        eval { $h = $call->(); 1 };
        is($@, "boom\n", "$name propagated the exception");
        is($h, 'unset', "$name returned nothing");
    }
};

# Tasks are dispatched with G_VOID, so a nested primitive sitting in a task's
# tail position - the module's flagship pattern - sees void context and
# allocates nothing. Every handle that is created becomes an object that is
# eventually destroyed, so counting DESTROY calls counts handles created.
subtest 'a nested primitive in tail position allocates no handle' => sub {
    my $made = 0;
    my $orig = \&EV::Future::Handle::DESTROY;
    no warnings 'redefine';
    local *EV::Future::Handle::DESTROY = sub { $made++; $orig->(@_) };

    $made = 0;
    parallel([sub { my $d = shift;
        parallel([sub { shift->() }], sub { $d->() }) }], sub { });
    is($made, 0, 'parallel');

    $made = 0;
    series([sub { my $d = shift;
        series([sub { shift->() }], sub { $d->() }) }], sub { });
    is($made, 0, 'series');

    $made = 0;
    parallel_limit([sub { my $d = shift;
        parallel_limit([sub { shift->() }], 1, sub { $d->() }) }], 1, sub { });
    is($made, 0, 'parallel_limit');

    $made = 0;
    race([sub { my $d = shift;
        race([sub { shift->() }], sub { $d->() }) }], sub { });
    is($made, 0, 'race');

    # The counter itself has to be able to move, or the four checks above
    # would pass with the handle machinery removed entirely.
    $made = 0;
    { my $h = parallel([sub { shift->() }], sub { }); }
    is($made, 1, 'an asked-for handle is still counted');
};

subtest 'DESTROY refuses invocants it did not create' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    # A class-method call hands DESTROY a plain string; reading a reference
    # out of it is exactly what the guard prevents.
    EV::Future::Handle->DESTROY;
    pass('class-method DESTROY is a no-op');

    {
        package My::EVF::Sub;
        our @ISA = ('EV::Future::Handle');
    }
    {
        my $obj = bless { canary => 42 }, 'My::EVF::Sub';
        $obj->DESTROY;
        is($obj->{canary}, 42, 'subclass body untouched');
    }   # and again implicitly, on scope exit
    pass('subclassed hashref object destroyed');

    is_deeply(\@warnings, [], 'no warnings from a foreign invocant');
};

subtest 'a second DESTROY is inert' => sub {
    my $h = parallel([], sub { });
    isa_ok($h, 'EV::Future::Handle');

    $h->DESTROY;
    is($$h, 0, 'the payload is zeroed by the first DESTROY');
    $h->DESTROY;
    pass('second explicit DESTROY did not double free');
    undef $h;
    pass('implicit DESTROY after the explicit ones did not double free');
};

# The handle is a blessed scalar holding a C pointer to one refcounted cell, so
# anything that duplicates the Perl object creates a second owner and a second
# free. CLONE_SKIP covers ithread cloning; Storable does not honour CLONE_SKIP
# and needs its own hooks. Without them this subtest aborts the process with
# "double free or corruption" (an invalid write in parallel_cleanup under
# valgrind, from ctx->h dangling after the copy's DESTROY freed the cell).
subtest 'a handle refuses to be duplicated' => sub {
    is(EV::Future::Handle->CLONE_SKIP, 1, 'CLONE_SKIP is set, so a thread clone yields undef');

    SKIP: {
        eval { require Storable; 1 } or skip 'Storable is not available', 5;

        my @dones;
        my $clone;
        {
            my $h = parallel([ (sub { push @dones, shift }) x 2 ], sub { });
            $clone = Storable::dclone($h);
            isa_ok($clone, 'EV::Future::Handle');
            isnt($$clone, $$h, 'the copy does not carry the original pointer');
            is($$clone, 0, 'the copy is an inert dead handle');
        }

        $clone->cancel;
        is($clone->pending, 0, 'the copy behaves like a finished operation');
        undef $clone;

        # The context still holds the original cell; completing the operation
        # writes through ctx->h, which is where a freed cell would show up.
        $_->() for @dones;
        pass('the operation completed after both objects went away');
    }
};

subtest 'cancel stops further dispatch' => sub {
    our @w;
    my ($dispatched, $final) = (0, 0);

    my $h = parallel_map_limit([1 .. 6], sub {
        my ($item, $done) = @_;
        $dispatched++;
        push @w, EV::timer 0.02, 0, sub { $done->() };
    }, 2, sub { $final++ });

    is($dispatched, 2, 'limit respected before cancel');
    $h->cancel;

    my $bail = EV::timer 0.2, 0, sub { EV::break };
    EV::run;

    is($dispatched, 2, 'no further items dispatched after cancel');
    is($final, 0, 'final_cb did not fire');
    @w = ();
};

subtest 'cancel(1) fires final_cb once with no arguments' => sub {
    our @w;
    my ($final, @args) = (0);

    my $h = parallel_limit([
        (sub { my $d = shift; push @w, EV::timer 0.02, 0, sub { $d->() } }) x 4,
    ], 2, sub { $final++; @args = @_ });

    $h->cancel(1);
    is($final, 1, 'final_cb fired exactly once');
    is_deeply(\@args, [], 'final_cb received no arguments');

    my $bail = EV::timer 0.2, 0, sub { EV::break };
    EV::run;
    is($final, 1, 'still exactly once after the loop drained');
    @w = ();
};

subtest 'cancel is idempotent and safe after completion' => sub {
    my $final = 0;
    my $h = parallel([sub { shift->() }], sub { $final++ });
    is($final, 1, 'completed synchronously');

    $h->cancel;
    $h->cancel(1);
    $h->cancel;
    is($final, 1, 'cancel after completion is a no-op');
};

subtest 'cancel from inside a task stops the dispatch loop' => sub {
    our @w;
    my ($dispatched, $final) = (0, 0);
    my $h;

    # With limit 2, items 1 and 2 dispatch synchronously inside this very
    # call, before the "$h = ..." assignment below can run - so $h is still
    # undef in their worker invocations and a guard of "$item == 1" could
    # never fire. Item 3 is the first one dispatched later from an EV
    # callback (once item 1 or 2 completes and frees a slot), by which point
    # $h is assigned; that is where cancel is actually exercised.
    $h = parallel_map_limit([1 .. 6], sub {
        my ($item, $done) = @_;
        $dispatched++;
        $h->cancel if $item == 3 && $h;
        push @w, EV::timer 0.02, 0, sub { $done->() };
    }, 2, sub { $final++ });

    my $bail = EV::timer 0.2, 0, sub { EV::break };
    EV::run;

    is($final, 0, 'final_cb did not fire');
    is($dispatched, 3, 'dispatch loop stopped right after the triggering task');
    @w = ();
};

subtest 'late done() after cancel is ignored' => sub {
    our @w;
    my $final = 0;
    my $saved_done;

    my $h = parallel([
        sub { $saved_done = shift },
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
    ], sub { $final++ });

    $h->cancel;
    $saved_done->();

    my $bail = EV::timer 0.2, 0, sub { EV::break };
    EV::run;
    is($final, 0, 'late done did not resurrect the operation');
    @w = ();
};

subtest 'cancel from inside final_cb is a no-op' => sub {
    our @w;
    my ($final, $err) = (0);
    my $h;

    # The task must be async. $h is assigned only after parallel() returns, so
    # a synchronous task would reach final_cb with $h still undefined and the
    # subtest would never exercise cancel at all.
    $h = parallel([
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->() } },
    ], sub {
        $final++;
        eval { $h->cancel(1) };
        $err = $@;
        EV::break;
    });

    EV::run;
    is($final, 1, 'final_cb fired exactly once, not re-entered by cancel(1)');
    ok(!$err, 'cancelling from final_cb did not die') or diag $err;
    @w = ();
};

subtest 'cancel from inside a task stops the series trampoline' => sub {
    our @w;
    my ($dispatched, $final) = (0, 0);
    my $h;

    # series dispatches its first task synchronously, inside this very call,
    # before the "$h = ..." assignment below can run - so $h is still undef
    # there, exactly as with parallel_map_limit above. The second task is the
    # first one reached later from _series_next's EV-driven trampoline, by
    # which point $h is assigned; that is where cancel is actually exercised.
    $h = series([
        sub { my $d = shift; $dispatched++; push @w, EV::timer 0.01, 0, sub { $d->() } },
        sub {
            my $d = shift;
            $dispatched++;
            $h->cancel if $h;
            push @w, EV::timer 0.01, 0, sub { $d->() };
        },
        sub { my $d = shift; $dispatched++; push @w, EV::timer 0.01, 0, sub { $d->() } },
    ], sub { $final++ });

    my $bail = EV::timer 0.2, 0, sub { EV::break };
    EV::run;

    is($final, 0, 'final_cb did not fire');
    is($dispatched, 2, 'series stopped after the cancelling task; the third never ran');
    @w = ();
};

subtest 'cancel prevents a race from settling' => sub {
    our @w;
    my ($final, @winner) = (0);
    my $saved_done;

    my $h = race([
        sub { $saved_done = shift },
        sub { my $d = shift; push @w, EV::timer 0.01, 0, sub { $d->('late') } },
    ], sub { $final++; @winner = @_ });

    $h->cancel;
    $saved_done->('early');

    my $bail = EV::timer 0.2, 0, sub { EV::break };
    EV::run;

    is($final, 0, 'final_cb did not fire');
    is_deeply(\@winner, [], 'no winner was recorded');
    @w = ();
};

subtest 'pending and active on parallel_limit' => sub {
    our @w;
    my @dones;

    my $h = parallel_limit([
        (sub { my $d = shift; push @dones, $d }) x 5,
    ], 2, sub { });

    is($h->active,  2, 'two tasks in flight, matching the limit');
    is($h->pending, 5, 'five tasks not yet completed');
    cmp_ok($h->active, '<', $h->pending, 'queued tasks are pending but not active');

    (shift @dones)->();
    is($h->active,  2, 'a replacement task was dispatched');
    is($h->pending, 4, 'one fewer pending');

    (shift @dones)->() while @dones;
    is($h->pending, 0, 'pending is zero once the operation is over');
    is($h->active,  0, 'active is zero once the operation is over');
    @w = ();
};

subtest 'pending and active on parallel' => sub {
    my @dones;
    my $h = parallel([
        (sub { my $d = shift; push @dones, $d }) x 3,
    ], sub { });

    is($h->pending, 3, 'all three pending');
    is($h->active,  3, 'parallel dispatches everything up front');

    (shift @dones)->();
    is($h->pending, 2, 'pending dropped by one');

    (shift @dones)->() while @dones;
    is($h->pending, 0, 'zero once complete');
};

subtest 'pending and active on series' => sub {
    my @dones;
    my $h = series([
        (sub { my $d = shift; push @dones, $d }) x 3,
    ], sub { });

    is($h->active,  1, 'series always has exactly one task in flight');
    is($h->pending, 3, 'three tasks not yet completed');

    (shift @dones)->();
    is($h->pending, 2, 'pending dropped by one');

    (shift @dones)->() while @dones;
    is($h->pending, 0, 'zero once complete');
    is($h->active,  0, 'zero once complete');
};

subtest 'pending and active on race' => sub {
    my @dones;
    my $h = race([
        (sub { my $d = shift; push @dones, $d }) x 3,
    ], sub { });

    is($h->pending, 3, 'all three dispatched and unsettled');
    is($h->active,  3, 'race collapses active into pending');

    (shift @dones)->('winner');
    is($h->pending, 0, 'settled, so nothing pending');
};

subtest 'counts are zero after cancel' => sub {
    my @dones;
    my $h = parallel([
        (sub { my $d = shift; push @dones, $d }) x 3,
    ], sub { });

    is($h->pending, 3, 'three pending before cancel');
    $h->cancel;
    is($h->pending, 0, 'zero after cancel');
    is($h->active,  0, 'zero after cancel');
};

subtest 'pending is readable from inside a task' => sub {
    our @w;
    my ($seen_pending, $seen_active);
    my $h;

    # The task must be async: $h is assigned only after series() returns, so a
    # synchronous task would see an undefined $h and the test would assert
    # nothing. Deferring through a timer means the handle exists by the time
    # the callback runs.
    $h = series([
        sub {
            my $d = shift;
            push @w, EV::timer 0.01, 0, sub {
                $seen_pending = $h->pending;
                $seen_active  = $h->active;
                $d->();
            };
        },
        sub { shift->() },
    ], sub { EV::break });

    EV::run;
    is($seen_pending, 2, 'pending counted both tasks from inside the first');
    is($seen_active,  1, 'active was 1 from inside a task');
    @w = ();
};

# Truthy-done lets a task cancel a series from inside itself (documented
# under CANCELLATION): it jumps current_idx to total_tasks and, unlike
# $h->cancel, still fires final_cb - the series finishes early rather than
# aborting. This subtest pins that outward contract: the is_deeply checks
# below confirm real task-list truncation and a single final_cb call, once
# for a synchronous cancelling task (the jump and cleanup complete before $h
# exists on the Perl side) and, as a distinct code path, once for an
# asynchronous one.
#
# The four pending/active assertions do not exercise the SERIES arm of
# evf_handle_count or its clamp: series_cleanup has already run by the time
# either read happens, so h->ctx is NULL and every read lands on the
# !h->ctx early return, not the switch. They would pass unchanged under any
# implementation of the SERIES arm, including a broken one - confirmed by
# neutering it. They stay because zero-after-cancellation is still part of
# the documented contract; it is just satisfied here by the detached-handle
# guard, not by the arm the surrounding text might otherwise suggest.
subtest 'truthy done cancels a series early and zeroes the counts' => sub {
    my @ran;
    my $h = series([
        sub { my $d = shift; push @ran, 0; $d->(1) },
        sub { my $d = shift; push @ran, 1; $d->() },
        sub { my $d = shift; push @ran, 2; $d->() },
    ], sub { push @ran, 'final' });

    is_deeply(\@ran, [0, 'final'], 'the cancelling task ran, then final_cb; tasks 1 and 2 did not');
    is($h->pending, 0, 'pending is zero after a truthy-done cancellation');
    is($h->active,  0, 'active is zero after a truthy-done cancellation');

    our @w;
    my @ran2;
    my $h2;
    $h2 = series([
        sub { my $d = shift; push @ran2, 0;
              push @w, EV::timer 0.01, 0, sub { $d->() } },
        sub { my $d = shift; push @ran2, 1; $d->(1) },
        sub { my $d = shift; push @ran2, 2; $d->() },
    ], sub { push @ran2, 'final'; EV::break });

    my $bail = EV::timer 0.2, 0, sub { EV::break };
    EV::run;

    is_deeply(\@ran2, [0, 1, 'final'], 'the third task never ran after task 1 cancelled');
    is($h2->pending, 0, 'pending is zero after an async truthy-done cancellation');
    is($h2->active,  0, 'active is zero after an async truthy-done cancellation');
    @w = ();
};

done_testing;
