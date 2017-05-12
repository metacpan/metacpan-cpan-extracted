package Gearman::Spawner::Supervisor;

use strict;
use warnings;

use Gearman::Spawner::Process;

sub process { Gearman::Spawner::Process->instance }

# forks a child process to run the manager in, then brings up requested workers
# returns the pid of the forked supervisor the "workers" parameter is a hash of
# worker class names to their respective startup arguments
sub start {
    my $class = shift;

    my $supervisor = $class->new(@_); # new takes the same parameters as start

    # try loading modules before fork so obvious compile errors get reported to
    # caller
    $supervisor->try_load_modules;

    my $pid = process->fork("[Gearman::Spawner] $0", 1);
    return $pid if $pid;

    $supervisor->spawn;

    process->loop;

    die "manager exited unexpectedly";
}

sub new {
    my $class = shift;
    return bless {
        # allowed parameters: servers, workers, preload
        @_,
        _pid => $$,
    }, $class;
}

# launch workers in subprocesses
sub spawn {
    my $self = shift;

    $self->load_modules;

    my $workers = $self->{workers};
    for my $class (keys %$workers) {
        my $config = $workers->{$class};

        my $count = delete $config->{count} || 1;

        for my $n (1 .. $count) {
            my $slot = $n;

            my $handle = process->maintain_subprocess(sub {
                $self->start_worker(
                    servers => $self->{servers},
                    class   => $class,
                    slot    => $slot,
                    %$config,
                );
            });
            $self->{_handles}{"$class #$n"} = $handle;
        }
    }

    return $self;
}

sub load_modules {
    my $self = shift;

    return if $self->{_loaded}++;

    my $preload = $self->{preload} || [];
    my $workers = $self->{workers};

    for my $module (@$preload, keys %$workers) {
        my $ok = eval qq{use $module; 1;};
        $@ && die $@;
        $ok || die "$module didn't return a true value";
    }
}

sub try_load_modules {
    my $self = shift;

    # run test in a subprocess so parent doesn't incur memory overhead of
    # modules it may not use
    my $pid = process->fork("module test");

    if (!$pid) {
        eval { $self->load_modules };
        exit 1 if $@;
        exit 0;
    }

    waitpid $pid, 0;
    if ($?) {
        # something unknown failed in child loader, repeat loading in this
        # process to expose error to caller
        $self->load_modules;
    }
}

# fork a worker process and start grabbing jobs
sub start_worker {
    my $self = shift;
    my %params = @_;

    my $supervisor_pid = $$;

    my $pid = process->fork("$params{class}-worker #$params{slot}");
    return $pid if $pid;

    my $worker = $params{class}->new(
        $params{servers}, $params{slot}, $params{data}
    );

    my $quitting = 0;
    my $jobs_done = 0;
    $SIG{INT} = $SIG{TERM} = sub { $quitting = 1 };
    while (!$quitting) {
        eval {
            $worker->work(stop_if => sub {1});
        };
        $@ && warn "$params{class} [$$] failed: $@";
        $jobs_done++;

        # bail if supervisor went away
        $quitting++ if getppid != $supervisor_pid;
        $quitting++ if $params{max_jobs} && $jobs_done > $params{max_jobs};
    }
    exit 0;
}

sub DESTROY {
    my $self = shift;
    return unless $self->{_pid} == $$;
    process->kill_maintained(values %{ $self->{_handles} });
}

1;
