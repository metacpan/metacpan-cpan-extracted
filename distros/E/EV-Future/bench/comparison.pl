use strict;
use warnings;
use Benchmark qw(:all);
use EV;
use EV::Future;
use Promise::XS;
use Future;
use Future::XS;
use Future::Utils qw(fmap_void);
use AnyEvent;
use Time::HiRes qw(time);

# Number of tasks to run
my $COUNT = 1000;
my $ITERATIONS = 5000;

# Prepare tasks
my @tasks = map { sub { my $d = shift; $d->() } } 1..$COUNT;

# --- Parallel Benchmarks ---

sub bench_ev_future_parallel {
    EV::Future::parallel(\@tasks, sub { });
}

sub bench_ev_future_parallel_unsafe {
    EV::Future::parallel(\@tasks, sub { }, 1);
}

sub bench_promise_xs_parallel {
    my @promises;
    for (1..$COUNT) {
        my ($deferred) = Promise::XS::deferred();
        $deferred->resolve();
        push @promises, $deferred->promise();
    }
    Promise::XS::all(@promises);
}

sub bench_future_xs_parallel {
    my @futures;
    for (1..$COUNT) {
        my $f = Future::XS->new;
        $f->done;
        push @futures, $f;
    }
    Future::XS->wait_all(@futures);
}

sub bench_anyevent_parallel {
    my $cv = AE::cv;
    for (1..$COUNT) {
        $cv->begin;
        $cv->end;
    }
}

# --- Series Benchmarks ---

sub bench_ev_future_series {
    EV::Future::series(\@tasks, sub { });
}

sub bench_ev_future_series_unsafe {
    EV::Future::series(\@tasks, sub { }, 1);
}

sub bench_promise_xs_series {
    my $p = Promise::XS::resolved();
    for (1..$COUNT) {
        $p = $p->then(sub { return Promise::XS::resolved(); });
    }
}

sub bench_future_xs_series {
    my $f = Future::XS->done;
    for (1..$COUNT) {
        $f = $f->then(sub { return Future::XS->done; });
    }
}

# Stack-safe and highly efficient AnyEvent series implementation
sub bench_anyevent_series_stack_safe {
    my $cv = AE::cv;
    my $idx = 0;
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
            if ($idx >= $COUNT) {
                $cv->send;
                last;
            }
            my $task = $tasks[$idx++];
            $task->($next);
        }
        $running = 0;
    };
    $next->();
    $cv->recv;
}

# --- Parallel Limit Benchmarks ---

sub bench_ev_future_parallel_limit {
    EV::Future::parallel_limit(\@tasks, 10, sub { });
}

sub bench_ev_future_parallel_limit_unsafe {
    EV::Future::parallel_limit(\@tasks, 10, sub { }, 1);
}

sub bench_future_fmap_void {
    my @items = 1..$COUNT;
    my $f = fmap_void {
        return Future->done;
    } foreach => \@items, concurrent => 10;
    $f->get;
}

print "Benchmarking $COUNT tasks ($ITERATIONS iterations):\n";

print "\n--- PARALLEL ---\n";
timethese($ITERATIONS, {
    'EV::Future::parallel'          => \&bench_ev_future_parallel,
    'EV::Future::parallel (unsafe)' => \&bench_ev_future_parallel_unsafe,
    'Promise::XS::all'              => \&bench_promise_xs_parallel,
    'Future::XS::wait_all'          => \&bench_future_xs_parallel,
    'AnyEvent::cv (begin/end)'      => \&bench_anyevent_parallel,
});

print "\n--- PARALLEL LIMIT (10) ---\n";
timethese($ITERATIONS, {
    'EV::Future::parallel_limit'          => \&bench_ev_future_parallel_limit,
    'EV::Future::parallel_limit (unsafe)' => \&bench_ev_future_parallel_limit_unsafe,
    'Future::Utils::fmap_void'            => \&bench_future_fmap_void,
});

print "\n--- SERIES ---\n";
timethese($ITERATIONS, {
    'EV::Future::series'            => \&bench_ev_future_series,
    'EV::Future::series (unsafe)'   => \&bench_ev_future_series_unsafe,
    'Promise::XS (chain)'           => \&bench_promise_xs_series,
    'Future::XS (chain)'            => \&bench_future_xs_series,
    'AnyEvent::cv (stack-safe)'     => \&bench_anyevent_series_stack_safe,
});
