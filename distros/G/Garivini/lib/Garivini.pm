package Garivini;

our $VERSION = '0.002';
$VERSION = eval $VERSION;

1;
__END__

=head1 NAME

Garivini - Mostly language agnostic job persistence engine for Gearman

=head1 DESCRIPTION

Garivini is a set of workers and an optional "shim" client for usage with
Gearman and MySQL to create an efficient job persistence layer. It can operate
in high throughput, or low latency modes.

=head1 SYNOPSIS

=head2 Throughput Mode

    # Set up workers (see below)
    use Garivini::Client;

    my $cli = Garivini::Client->new(dbs => {
        1 => { id => 1, dsn => 'DBI:mysql:job:host=127.0.0.1', user => 'job',
            pass => 'job' } });
    $cli->insert_job(funcname => 'hello', arg => 'world');

    # Meanwhile, in a worker
    use Gearman::Worker;
    use Garivini::Client;
    use JSON;

    my $cli = Garivini::Client->new(dbs => {
        1 => { id => 1, dsn => 'DBI:mysql:job:host=127.0.0.1', user => 'job',
            pass => 'job' } });
    my $worker = Gearman::Worker->new;
    $worker->job_servers('127.0.0.1');
    $worker->register_function('hello' => \&hello);
    $worker->work;

    sub hello {
        my $job = decode_json(${$_[0]->argref});
        print "Hello ", $job->{arg}, "\n";
        $cli->complete_job($job);
    }

See L<Garivini::Client> for more.

=head2 Low Latency Mode

    # Client
    use Gearman::Client;
    use JSON;

    my $cli = Gearman::Client->new;
    $cli->job_servers('127.0.0.1');
    $cli->do_task('inject_jobs', \encode_json({ funcname => 'hello',
        arg => 'world' }));

    # Worker
    use Gearman::Worker;
    use JSON;

    my $worker = Gearman::Worker->new;
    $worker->job_servers('127.0.0.1');
    $worker->register_function('hello' => \&hello);
    $worker->work;

    sub hello {
        my $job = decode_json(${$_[0]->argref});
        print "Hello ", $job->{arg}, "\n";
        # Job completed successfully!
    }

=head1 UTILITIES

Example utilities are provided in the source. A "Garivini" script shows how to
start any of the workers.

"gv_inject" shows an example client, running in either major mode.

"gv_consume" is an example worker, also runnable in either major mode.

=head1 DESIGN AND USE

=head2 General design

Garivini is a job persistence layer for Gearman. A "job" can be any binary blob
of data. It persists jobs into a MySQL server, then executes them
asynchronously.

Two main modes of operation are supported: High Throughput, where a small
client is used to directly inject jobs, and a worker asynchronously sends the
jobs back through Gearman in bulk. Also a Low Latency, or Pure Gearman mode,
where jobs are wrapped in JSON and sent through Gearman to a set of special
workers, which persists then execute the job themselves immediately.

=head2 High Throughput

In High Throughput mode, L<Garivini::Client> is used to insert jobs directly
into MySQL. A L<Garivini::QueueRunner> worker then pulls jobs back out of the
database in batches, submitting them to Gearman to run the actual work.

Gearman workers then use L<Garivini::Client> to directly remove or reschedule
the job upon completion.

You will need to run a handful of QueueRunner workers to manage the queue, but
it is not necessary to run many of them.

This combination easily allows millions of jobs to quickly pass through the
system. The tradeoff is a delay between inserting a job into the queue, and the
L<Garivini::QueueRunner> workers submitting the job to Gearman. A typical setup
would have an average latency of one second. This could be lowered or
increased, based on tuning decisions.

Any language may be used to submit or work on jobs, so long as they implement
the simple L<Garivini::Client> library natively.

=head2 Low Latency (or Pure Gearman)

In Low Latency mode, L<Gearman::Client> is used to submit jobs to a
L<Garivini::Injector> worker, which listens for jobs sent to "inject_jobs".
Jobs must first be encoded in JSON, containing a "funcname" for the final
Gearman worker to send the job to, and an "arg" which contains the payload.

After submitting a synchronous job to L<Garivini::Injector>, the Injector
saves the job into MySQL, and immediately asynchronously submits the job to
Gearman via a L<Garivini::Controller> worker, which ultimately executes the
job.

The L<Garivini::Controller> worker listens for "run_queued_job" work. When it
receives a job, it synchronously submits it back through Gearman via the
assigned "funcname" argument of the job. Once the job completes, it directly
removes or reschedules the job from MySQL.

You will need to run enough Injector and Controller workers to handle desired
throughput.

This combination allows reliable low latency persistent job submission. Once
a job is submitted initially to Gearman, it has been persisted. It is then
immediately scheduled for work by its actual function. The tradeoff is harmed
throughput and slightly higher latency than memory-only Gearman, as a job has
to pass through several workers back and forth through Gearman.

This combination also allows you to easily use persistent jobs from any
language client, to any language worker. Any client or worker languge with
Gearman and JSON libraries can submit work and run work, the Injector and
Controller workers take care of the queue.

You also need to run a small number of L<Garivini::QueueRunner> workers to
handle resubmitting failed jobs.

=head2 Large Queues

EXPERIMENTAL!

One downside of Gearman is all in-flight jobs must fit in RAM across all of
your Gearman server instances. Garivini allows you to limit how many jobs
should be waiting for each worker queue.

If you specify a limit of 4000, at most 4000 jobs will wait for any particular
worker queue. Any further jobs are rescheduled in the database, and the
QueueRunner will attempt to submit them again at a later time.

This feature is experimental due to some corner cases:

Queue depth is fetched via the Gearman "status" command, which is slow if
there are many jobs queued. A new fast "queue depth" command must be
implemented for this feature to retain speed.

In low latency mode, jobs can be quickly submitted through the Injector
worker. If the Injector workers fall behind, Gearmand can still run out of
memory.

=head1 SETUP

TODO: Expand this.

Use the "schema.sql" file located in the source to create the necessary
database table. Fire up some workers, and away you go.

=head1 SEE ALSO

L<Gearman::Client> L<Gearman::Worker>

Module inspired by L<TheSchwartz> - a scalable but slow job persistence
system.

=head1 CONTRIBUTING

Easiest method is to submit pull requests on github. See
L<http://github.com/dormando/Garivini>. Patches welcome!

=head1 AUTHORS

Dormando (bulk of code, throughput design)

Adam Thomason (low latency worker code)

Design, testing:

Yann Kerherve

Martin Atkins

Hachi

=head1 COPYRIGHT

Copyright 2011 Dormando

Copyright 2011 SAY Media

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
