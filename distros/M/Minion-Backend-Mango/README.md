[![Build Status](https://travis-ci.org/avkhozov/Minion-Backend-Mango.svg?branch=master)](https://travis-ci.org/avkhozov/Minion-Backend-Mango)
# NAME

Minion::Backend::Mango - Mango backend for Minion

# SYNOPSIS

    use Minion::Backend::Mango;

    my $backend = Minion::Backend::Mango->new('mongodb://127.0.0.1:27017');

# DESCRIPTION

[Minion::Backend::Mango](https://metacpan.org/pod/Minion::Backend::Mango) is a highly scalable [Mango](https://metacpan.org/pod/Mango) backend for [Minion](https://metacpan.org/pod/Minion).

# ATTRIBUTES

[Minion::Backend::Mango](https://metacpan.org/pod/Minion::Backend::Mango) inherits all attributes from [Minion::Backend](https://metacpan.org/pod/Minion::Backend) and
implements the following new ones.

## mango

    my $mango = $backend->mango;
    $backend  = $backend->mango(Mango->new);

[Mango](https://metacpan.org/pod/Mango) object used to store collections.

## jobs

    my $jobs = $backend->jobs;
    $backend = $backend->jobs(Mango::Collection->new);

[Mango::Collection](https://metacpan.org/pod/Mango::Collection) object for `jobs` collection, defaults to one based on ["prefix"](#prefix).

## notifications

    my $notifications = $backend->notifications;
    $backend          = $backend->notifications(Mango::Collection->new);

[Mango::Collection](https://metacpan.org/pod/Mango::Collection) object for `notifications` collection, defaults to one based on ["prefix"](#prefix).

## prefix

    my $prefix = $backend->prefix;
    $backend   = $backend->prefix('foo');

Prefix for collections, defaults to `minion`.

## workers

    my $workers = $backend->workers;
    $backend    = $backend->workers(Mango::Collection->new);

[Mango::Collection](https://metacpan.org/pod/Mango::Collection) object for `workers` collection, defaults to one based on ["prefix"](#prefix).

# METHODS

[Minion::Backend::Mango](https://metacpan.org/pod/Minion::Backend::Mango) inherits all methods from [Minion::Backend](https://metacpan.org/pod/Minion::Backend) and implements the following new ones.

## dequeue

    my $job_info = $backend->dequeue($worker_id, 0.5);
    my $job_info = $backend->dequeue($worker_id, 0.5, {queues => ['default']});

Wait for job, dequeue it and transition from `inactive` to `active` state or
return `undef` if queue was empty.

These options are currently available:

- queues

        queues => ['important']

    One or more queues to dequeue jobs from, defaults to `default`.

## enqueue

    my $job_id = $backend->enqueue('foo');
    my $job_id = $backend->enqueue(foo => [@args]);
    my $job_id = $backend->enqueue(foo => [@args] => {priority => 1});

Enqueue a new job with `inactive` state. These options are currently available:

- attempts

        attempts => 25

    Number of times performing this job will be attempted, defaults to `1`.

- delay

        delay => 10

    Delay job for this many seconds from now.

- priority

        priority => 5

    Job priority, defaults to `0`.

- queue

        queue => 'important'

    Queue to put job in, defaults to `default`.

## fail\_job

    my $bool = $backend->fail_job($job_id);
    my $bool = $backend->fail_job($job_id, 'Something went wrong!');

Transition from `active` to `failed` state.

## finish\_job

    my $bool = $backend->finish_job($job_id);

Transition from `active` to `finished` state.

## job\_info

    my $info = $backend->job_info($job_id);

Get information about a job or return `undef` if job does not exist.

## list\_jobs

    my $batch = $backend->list_jobs($skip, $limit);
    my $batch = $backend->list_jobs($skip, $limit, {state => 'inactive'});

Returns the same information as ["job\_info"](#job_info) but in batches.

These options are currently available:

- queue

        queue => 'important'

    List only jobs in this queue.

- state

        state => 'inactive'

    List only jobs in this state.

- task

        task => 'test'

    List only jobs for this task.

## list\_workers

    my $batch = $backend->list_workers($skip, $limit);

Returns the same information as ["worker\_info"](#worker_info) but in batches.

## new

    my $backend = Minion::Backend::Mango->new('mongodb://127.0.0.1:27017');

Construct a new [Minion::Backend::Mango](https://metacpan.org/pod/Minion::Backend::Mango) object.

## register\_worker

    my $worker_id = $backend->register_worker;
    my $worker_id = $backend->register_worker($worker_id);

Register worker or send heartbeat to show that this worker is still alive.

## remove\_job

    my $bool = $backend->remove_job($job_id);

Remove `failed`, `finished` or `inactive` job from queue.

## repair

    $backend->repair;

Repair worker registry and job queue if necessary.

## reset

    $backend->reset;

Reset job queue.

## retry\_job

    my $bool = $backend->retry_job($job_id);
    my $bool = $backend->retry_job($job_id, {delay => 10});

Transition from `failed` or `finished` state back to `inactive`, already
`inactive` jobs may also be retried to change options.

These options are currently available:

- delay

        delay => 10

    Delay job for this many seconds (from now).

- priority

        priority => 5

    Job priority.

- queue

        queue => 'important'

    Queue to put job in.

## stats

    my $stats = $backend->stats;

Get statistics for jobs and workers.

## unregister\_worker

    $backend->unregister_worker($worker_id);

Unregister worker.

## worker\_info

    my $info = $backend->worker_info($worker_id);

Get information about a worker or return `undef` if worker does not exist.

# AUTHOR

Andrey Khozov <avkhozov@gmail.com>

Sebastian Riedel <sri@cpan.org>

# LICENSE

Copyright (C) 2014, Sebastian Riedel.

Copyright (C) 2015-2016, Andrey Khozov.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# SEE ALSO

[Minion](https://metacpan.org/pod/Minion), [Mango](https://metacpan.org/pod/Mango), [http://mojolicio.us](http://mojolicio.us).
