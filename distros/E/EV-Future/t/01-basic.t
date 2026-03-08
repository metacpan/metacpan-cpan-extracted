use strict;
use warnings;
use Test::More;
use EV;
use EV::Future;

subtest 'parallel' => sub {
    my @done;
    my $finished = 0;
    
    parallel([
        sub {
            my $done = shift;
            push @done, 1;
            $done->();
        },
        sub {
            my $done = shift;
            push @done, 2;
            $done->();
        },
        sub {
            my $done = shift;
            push @done, 3;
            $done->();
        }
    ], sub {
        $finished = 1;
    });
    
    is($finished, 1, 'Parallel finished');
    is_deeply([sort @done], [1, 2, 3], 'All parallel tasks ran');
};

subtest 'series' => sub {
    my @done;
    my $finished = 0;
    
    series([
        sub {
            my $done = shift;
            push @done, 1;
            $done->();
        },
        sub {
            my $done = shift;
            push @done, 2;
            $done->();
        },
        sub {
            my $done = shift;
            push @done, 3;
            $done->();
        }
    ], sub {
        $finished = 1;
    });
    
    is($finished, 1, 'Series finished');
    is_deeply(\@done, [1, 2, 3], 'Series tasks ran in order');
};

subtest 'stress' => sub {
    my $count = 1000;
    my $done_count = 0;
    my @tasks;
    for (1..$count) {
        push @tasks, sub {
            my $done = shift;
            $done_count++;
            $done->();
        };
    }
    
    parallel(\@tasks, sub { });
    is($done_count, $count, "Ran $count parallel tasks");
};

subtest 'edge_cases' => sub {
    # Empty array
    my $finished = 0;
    parallel([], sub { $finished = 1 });
    ok($finished, 'Parallel handles empty tasks');
    
    $finished = 0;
    series([], sub { $finished = 1 });
    ok($finished, 'Series handles empty tasks');
    
    # Task list with undef/invalid
    $finished = 0;
    parallel([undef, sub { shift->() }, 1], sub { $finished = 1 });
    ok($finished, 'Parallel handles invalid tasks');

    $finished = 0;
    series([undef, sub { shift->() }, 1], sub { $finished = 1 });
    ok($finished, 'Series handles invalid tasks');
};

subtest 'sync_completion' => sub {
    my $finished = 0;
    parallel([ sub { shift->() } ], sub { $finished = 1 });
    ok($finished, 'Parallel handles synchronous completion');

    $finished = 0;
    series([ sub { shift->() } ], sub { $finished = 1 });
    ok($finished, 'Series handles synchronous completion');
};

subtest 'exceptions' => sub {
    eval {
        parallel([ sub { shift->() } ], sub { die "parallel final die\n" });
    };
    is($@, "parallel final die\n", 'parallel handles exception in final cb');

    eval {
        series([ sub { shift->() } ], sub { die "series final die\n" });
    };
    is($@, "series final die\n", 'series handles exception in final cb');

    # Non-coderef task path triggering final_cb exception
    eval {
        parallel([undef], sub { die "parallel nonref final die\n" });
    };
    is($@, "parallel nonref final die\n", 'parallel handles final_cb exception (non-coderef path)');

    eval {
        series([undef], sub { die "series nonref final die\n" });
    };
    is($@, "series nonref final die\n", 'series handles final_cb exception (non-coderef path)');
};

subtest 'invalid_inputs' => sub {
    # Non-coderef final_cb should not crash
    eval { parallel([ sub { shift->() } ], undef) };
    ok(!$@, 'parallel survives non-coderef final_cb');

    eval { series([ sub { shift->() } ], undef) };
    ok(!$@, 'series survives non-coderef final_cb');
};

subtest 'task_exceptions' => sub {
    # Task dying should propagate exception
    eval {
        parallel([ sub { die "parallel task died\n" } ], sub { });
    };
    is($@, "parallel task died\n", 'parallel handles task exception');

    eval {
        series([ sub { die "series task died\n" } ], sub { });
    };
    is($@, "series task died\n", 'series handles task exception');
};

subtest 'exception_cleanup' => sub {
    for (1..3) {
        eval { series([ sub { die "oops\n" } ], sub { }) };
        is($@, "oops\n", "Exception re-thrown (iteration $_)");
    }
    my $ran = 0;
    series([ sub { shift->(); $ran = 1 } ], sub { });
    is($ran, 1, "Can run tasks after exceptions");

    for (1..3) {
        eval { parallel_limit([ sub { die "oops\n" } ], 2, sub { }) };
        is($@, "oops\n", "plimit exception re-thrown (iteration $_)");
    }
    $ran = 0;
    parallel_limit([ sub { shift->(); $ran = 1 } ], 2, sub { });
    is($ran, 1, "Can run parallel_limit tasks after exceptions");
};

subtest 'double_call_protection' => sub {
    # parallel safe mode
    my $p_final = 0;
    my @p_dones;
    parallel([
        sub { push @p_dones, shift; $p_dones[-1]->() },
        sub { push @p_dones, shift; $p_dones[-1]->() },
    ], sub { $p_final++ });
    $_->() for @p_dones;
    is($p_final, 1, 'parallel ignores double-call on done');

    # series safe mode
    my $s_final = 0;
    my @s_dones;
    series([
        sub { my $d = shift; push @s_dones, $d; $d->() },
        sub { my $d = shift; push @s_dones, $d; $d->() },
    ], sub { $s_final++ });
    $_->() for @s_dones;
    is($s_final, 1, 'series ignores double-call on done');
};

subtest 'cancellation' => sub {
    my $task2_ran = 0;
    my $finished = 0;
    series([
        sub { shift->(1) },
        sub { $task2_ran = 1; shift->() }
    ], sub { $finished = 1 });
    
    is($task2_ran, 0, 'series task 2 skipped after cancellation');
    is($finished, 1, 'series final_cb called after cancellation');

    $task2_ran = 0;
    $finished = 0;
    series([
        sub { 
            my $d = shift;
            our $w = EV::timer 0.01, 0, sub { $d->(1) };
        },
        sub { $task2_ran = 1; shift->() }
    ], sub { $finished = 1; EV::break });
    EV::run;
    is($task2_ran, 0, 'async series task 2 skipped after cancellation');
    is($finished, 1, 'async series final_cb called after cancellation');
};

subtest 'deep_recursion' => sub {
    my $count = 5000;
    my $done_count = 0;
    my @tasks;
    for (1..$count) {
        push @tasks, sub { shift->(); $done_count++ };
    }

    $done_count = 0;
    series(\@tasks, sub { });
    is($done_count, $count, "series handles $count synchronous tasks (no stack overflow)");

    $done_count = 0;
    parallel(\@tasks, sub { });
    is($done_count, $count, "parallel handles $count synchronous tasks");
};

subtest 'unsafe_mode' => sub {
    my $parallel_ran = 0;
    my $parallel_fin = 0;
    parallel([ sub { $parallel_ran = 1; shift->() } ], sub { $parallel_fin = 1 }, 1);
    is($parallel_ran, 1, 'parallel unsafe mode executes');
    is($parallel_fin, 1, 'parallel unsafe final_cb called');

    my $series_ran = 0;
    my $series_fin = 0;
    series([ sub { $series_ran = 1; shift->() } ], sub { $series_fin = 1 }, 1);
    is($series_ran, 1, 'series unsafe mode executes');
    is($series_fin, 1, 'series unsafe final_cb called');

    # Unsafe parallel with multiple tasks (SP drift regression)
    my $multi_count = 0;
    my $multi_fin = 0;
    parallel(
        [ map { sub { $multi_count++; shift->() } } 1..100 ],
        sub { $multi_fin = 1 },
        1,
    );
    is($multi_count, 100, 'unsafe parallel: all 100 tasks ran');
    is($multi_fin, 1, 'unsafe parallel: final_cb called');

    # Cancellation in unsafe series
    my $task2_ran = 0;
    my $cancel_fin = 0;
    series([
        sub { shift->(1) },
        sub { $task2_ran = 1; shift->() }
    ], sub { $cancel_fin = 1 }, 1);
    is($task2_ran, 0, 'unsafe series cancellation skips task 2');
    is($cancel_fin, 1, 'unsafe series cancellation calls final_cb');
};

subtest 'array_modification' => sub {
    my @my_tasks;
    push @my_tasks, sub { @my_tasks = () };
    push @my_tasks, sub { shift->() };
    
    eval {
        parallel(\@my_tasks, sub { });
    };
    ok(!$@, 'Parallel survives drastic array modification');

    @my_tasks = ();
    push @my_tasks, sub { @my_tasks = () };
    push @my_tasks, sub { shift->() };
    eval {
        series(\@my_tasks, sub { });
    };
    ok(!$@, 'Series survives drastic array modification');
};

subtest 'holes_and_magic' => sub {
    my $tasks = [];
    $tasks->[2] = sub { shift->() }; 
    eval { parallel($tasks, sub { }) };
    ok(!$@, 'Parallel handles array with holes');

    eval { series($tasks, sub { }) };
    ok(!$@, 'Series handles array with holes');

    package TiedArray;
    sub TIEARRAY { bless [], shift }
    sub FETCH { $_[0][$_[1]] }
    sub STORE { $_[0][$_[1]] = $_[2] }
    sub FETCHSIZE { scalar @{$_[0]} }
    sub DESTROY {}

    package main;
    my @magic;
    tie @magic, 'TiedArray';
    $magic[2] = sub { shift->() };
    
    eval { parallel(\@magic, sub { }) };
    ok(!$@, 'Parallel handles magic array with holes');

    eval { series(\@magic, sub { }) };
    ok(!$@, 'Series handles magic array with holes');
};

subtest 'parallel_limit' => sub {
    # Basic: limit < len
    my @order;
    my $finished = 0;
    my $max_active = 0;
    my $active = 0;
    parallel_limit([
        map { my $i = $_; sub {
            my $done = shift;
            $active++;
            $max_active = $active if $active > $max_active;
            push @order, $i;
            $active--;
            $done->();
        } } 1..6
    ], 2, sub { $finished = 1 });
    is($finished, 1, 'parallel_limit finished');
    is(scalar @order, 6, 'all 6 tasks ran');
    ok($max_active <= 2, 'respects limit (sync tasks complete before next dispatch)');

    # limit >= len degenerates to parallel
    @order = ();
    $finished = 0;
    parallel_limit([
        sub { push @order, 1; shift->() },
        sub { push @order, 2; shift->() },
    ], 10, sub { $finished = 1 });
    is($finished, 1, 'parallel_limit with limit >= len finishes');
    is_deeply([sort @order], [1, 2], 'all tasks ran with high limit');

    # limit == 1 degenerates to series
    @order = ();
    $finished = 0;
    parallel_limit([
        sub { push @order, 1; shift->() },
        sub { push @order, 2; shift->() },
        sub { push @order, 3; shift->() },
    ], 1, sub { $finished = 1 });
    is($finished, 1, 'parallel_limit with limit=1 finishes');
    is_deeply(\@order, [1, 2, 3], 'limit=1 runs tasks in order');

    # Empty tasks
    $finished = 0;
    parallel_limit([], 5, sub { $finished = 1 });
    is($finished, 1, 'parallel_limit handles empty tasks');

    # Mixed coderef/non-coderef
    $finished = 0;
    parallel_limit([undef, sub { shift->() }, 1], 2, sub { $finished = 1 });
    is($finished, 1, 'parallel_limit handles mixed tasks');

    # Exception in task (safe mode)
    eval {
        parallel_limit([sub { die "plimit die\n" }], 2, sub { });
    };
    is($@, "plimit die\n", 'parallel_limit propagates task exception');

    # Unsafe mode
    my $ran = 0;
    parallel_limit([sub { $ran = 1; shift->() }], 2, sub { }, 1);
    is($ran, 1, 'parallel_limit unsafe mode executes');

    # Unsafe mode multi-task (SP drift regression)
    my $unsafe_count = 0;
    my $unsafe_fin = 0;
    parallel_limit(
        [map { sub { $unsafe_count++; shift->() } } 1..100],
        10, sub { $unsafe_fin = 1 }, 1
    );
    is($unsafe_count, 100, 'unsafe parallel_limit: all 100 sync tasks ran');
    is($unsafe_fin, 1, 'unsafe parallel_limit: final_cb called');

    # Stress with small limit
    my $done_count = 0;
    my @tasks = map { sub { $done_count++; shift->() } } 1..1000;
    parallel_limit(\@tasks, 10, sub { });
    is($done_count, 1000, 'parallel_limit stress: 1000 tasks, limit 10');
};

subtest 'parallel_limit_extras' => sub {
    # Exception in final_cb
    eval {
        parallel_limit([ sub { shift->() } ], 2, sub { die "plimit final die\n" });
    };
    is($@, "plimit final die\n", 'parallel_limit handles exception in final cb');

    # Exception in final_cb via non-coderef completion path
    eval {
        parallel_limit([undef, undef], 2, sub { die "nonref final die\n" });
    };
    is($@, "nonref final die\n", 'parallel_limit handles final_cb exception (non-coderef path)');

    # Double-call protection (safe mode)
    my $final_count = 0;
    my @saved_dones;
    parallel_limit([
        sub { push @saved_dones, shift; $saved_dones[-1]->() },
        sub { push @saved_dones, shift; $saved_dones[-1]->() },
    ], 2, sub { $final_count++ });
    # Call done again — should be ignored
    $_->() for @saved_dones;
    is($final_count, 1, 'parallel_limit ignores double-call on done');

    # Array with holes
    my $tasks = [];
    $tasks->[2] = sub { shift->() };
    eval { parallel_limit($tasks, 2, sub { }) };
    ok(!$@, 'parallel_limit handles array with holes');

    # Magic array
    {
        my @magic;
        tie @magic, 'TiedArray';
        $magic[2] = sub { shift->() };
        eval { parallel_limit(\@magic, 2, sub { }) };
        ok(!$@, 'parallel_limit handles magic array with holes');
    }

    # All non-coderef tasks
    my $all_undef_fin = 0;
    parallel_limit([undef, undef, undef], 2, sub { $all_undef_fin = 1 });
    is($all_undef_fin, 1, 'parallel_limit handles all-undef tasks');

    # Undef final_cb
    eval { parallel_limit([ sub { shift->() } ], 2, undef) };
    ok(!$@, 'parallel_limit survives non-coderef final_cb');

    # Limit = 0 (clamped to 1)
    my $zero_limit_fin = 0;
    parallel_limit([ sub { shift->() } ], 0, sub { $zero_limit_fin = 1 });
    is($zero_limit_fin, 1, 'parallel_limit clamps limit=0 to 1');
};

subtest 'all_non_coderef' => sub {
    my $fin = 0;
    series([undef, undef, undef], sub { $fin = 1 });
    is($fin, 1, 'series handles all-non-coderef tasks');

    $fin = 0;
    parallel([undef, undef], sub { $fin = 1 });
    is($fin, 1, 'parallel handles all-non-coderef tasks');
};

subtest 'unsafe_async' => sub {
    # parallel unsafe async
    my ($p_ran, $p_fin) = (0, 0);
    our @uw;
    parallel([
        map { sub { my $d = shift; push @uw, EV::timer 0.01, 0, sub { $p_ran++; $d->() } } } 1..3
    ], sub { $p_fin = 1; EV::break }, 1);
    EV::run;
    is($p_ran, 3, 'unsafe parallel: all async tasks ran');
    is($p_fin, 1, 'unsafe parallel: final_cb called');
    @uw = ();

    # parallel_limit unsafe async
    my ($pl_ran, $pl_fin) = (0, 0);
    parallel_limit([
        map { sub { my $d = shift; push @uw, EV::timer 0.01, 0, sub { $pl_ran++; $d->() } } } 1..4
    ], 2, sub { $pl_fin = 1; EV::break }, 1);
    EV::run;
    is($pl_ran, 4, 'unsafe parallel_limit: all async tasks ran');
    is($pl_fin, 1, 'unsafe parallel_limit: final_cb called');
    @uw = ();

    # series unsafe async
    my ($s_ran, $s_fin) = (0, 0);
    series([
        map { sub { my $d = shift; push @uw, EV::timer 0.01, 0, sub { $s_ran++; $d->() } } } 1..3
    ], sub { $s_fin = 1; EV::break }, 1);
    EV::run;
    is($s_ran, 3, 'unsafe series: all async tasks ran');
    is($s_fin, 1, 'unsafe series: final_cb called');
    @uw = ();
};

subtest 'parallel_limit_async' => sub {
    # Async: verify concurrency limit with timers
    my $max_active = 0;
    my $active = 0;
    my $done_count = 0;
    our @w;

    parallel_limit([
        map { sub {
            my $done = shift;
            $active++;
            $max_active = $active if $active > $max_active;
            push @w, EV::timer 0.01, 0, sub {
                $active--;
                $done_count++;
                $done->();
            };
        } } 1..6
    ], 3, sub { EV::break });

    EV::run;
    is($done_count, 6, 'all 6 async tasks completed');
    ok($max_active <= 3, "max active ($max_active) <= limit 3");
    @w = ();

    # Out-of-order completion with variable delays
    ($done_count, $max_active, $active) = (0, 0, 0);
    my @delays = (0.04, 0.01, 0.03, 0.01, 0.02);
    parallel_limit([
        map { my $d = $_; sub {
            my $done = shift;
            $active++; $max_active = $active if $active > $max_active;
            push @w, EV::timer $d, 0, sub { $active--; $done_count++; $done->() };
        }} @delays
    ], 2, sub { EV::break });
    EV::run;
    is($done_count, 5, 'all 5 out-of-order tasks completed');
    ok($max_active <= 2, "out-of-order max active ($max_active) <= limit 2");
    @w = ();
};

done_testing;
