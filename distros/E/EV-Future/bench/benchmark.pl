use strict;
use warnings;
use EV;
use EV::Future;
use Time::HiRes qw(time);

my $COUNT = 100;
my $ITERATIONS = 50000;

# Reuse tasks to avoid allocation overhead in loop
my @tasks = map { sub { my $d = shift; $d->() } } 1..$COUNT;

sub run_bench {
    my ($name, $code) = @_;
    print "Running $name...\n";
    my $start = time;
    for (1..$ITERATIONS) {
        $code->();
    }
    my $end = time;
    my $elapsed = $end - $start;
    printf "%-30s: %8.4fs (%10.2f/s)\n", $name, $elapsed, $ITERATIONS / $elapsed;
}

print "Benchmarking $COUNT synchronous tasks over $ITERATIONS iterations:\n";

run_bench('EV::Future::parallel', sub {
    EV::Future::parallel(\@tasks, sub { });
});

run_bench('EV::Future::parallel (unsafe)', sub {
    EV::Future::parallel(\@tasks, sub { }, 1);
});

run_bench('EV::Future::parallel_limit(10)', sub {
    EV::Future::parallel_limit(\@tasks, 10, sub { });
});

run_bench('EV::Future::parallel_limit(10,unsafe)', sub {
    EV::Future::parallel_limit(\@tasks, 10, sub { }, 1);
});

run_bench('EV::Future::series', sub {
    EV::Future::series(\@tasks, sub { });
});

run_bench('EV::Future::series (unsafe)', sub {
    EV::Future::series(\@tasks, sub { }, 1);
});

run_bench('naive_parallel_non_recursive', sub {
    naive_parallel_non_recursive(\@tasks, sub { });
});

run_bench('naive_series_non_recursive', sub {
    naive_series_non_recursive(\@tasks, sub { });
});

sub naive_series_non_recursive {
    my ($tasks, $final_cb) = @_;
    my $idx = 0;
    my $len = @$tasks;
    return $final_cb->() if $len == 0;
    my $running = 0;
    my $delayed = 0;
    my $next;
    $next = sub {
        if ($running) {
            $delayed = 1;
            return;
        }
        $running = 1;
        $delayed = 1;
        while ($delayed) {
            $delayed = 0;
            if ($idx >= $len) {
                $final_cb->();
                last;
            }
            my $task = $tasks->[$idx];
            $idx++;
            $task->($next);
        }
        $running = 0;
    };
    $next->();
}

sub naive_parallel_non_recursive {
    my ($tasks, $final_cb) = @_;
    my $remaining = scalar @$tasks;
    if ($remaining == 0) {
        $final_cb->();
        return;
    }
    my $should_call_final = 0;
    my $done = sub {
        $remaining--;
        if ($remaining <= 0) {
            $should_call_final = 1;
        }
    };
    foreach my $task (@$tasks) {
        $task->($done);
    }
    if ($should_call_final) {
        $final_cb->();
    }
}
