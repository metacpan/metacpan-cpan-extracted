package Garivini::QueueRunner;

=head1 NAME

Garivini::QueueRunner - Asynchronously batch queue jobs

=head1 DESCRIPTION

Required in all run modes, QueueRunner workers pull jobs out of a Garivini
database in batches and submit them asynchronously through Gearman for
execution. It then sleeps for a moment and runs again.

It pulls jobs ordered by when they should be executed, and tries to only push
them into Gearman if the queues are not overloaded (see queue_watermark_depth
below).

You need enough workers to pull jobs out of the DB as fast as they go in. If
running in low latency mode, you need fewer QueueRunners. If in high
throughput mode, you still don't need many, but enough. See below for more
information.

=head1 SYNOPSIS

    my $worker = Garivini::Controller->new(dbs => {
        1 => { id => 1, dsn => 'DBI:mysq:job:host=127.0.0.1', user => 'job',
            pass => 'job' } },
        job_servers => ['127.0.0.1'],
        queue_watermark_depth => 4000,
        batch_run_sleep => 1);
    $worker->work;

=head1 OPTIONS

=over

=item queue_watermark_depth

When pulling jobs from the database, but before submitting back through
Gearman, the queue depth for a job's function is checked. If there are more
than queue_watermark_depth jobs presently waiting for execution, the job will
be rescheduled in the database. This allows faster jobs to bubble down and be
executed, and primarily attempting to not run Gearmand out of memory by
overqueueing work.

Set to 0 to disable.

=item batch_run_sleep

After submitting jobs to Gearmand, sleep for this many seconds. Increase this
value to avoid hammering your database (or Gearmand) as much.

Defaults to 1 second.

=item batch_max_size

QueueRunner's fetch as few jobs as they can at once, in order to allow other
QueueRunner's to process some work in parallel. The more jobs there are
waiting, the more it will pull at once, up to batch_max_size. See below for
more information.

Defaults to 1000

=back

=head1 Calculating max job rate

You should calculate how many workers you need and what to set their options
to by how many jobs you expect to process per second.

If batch_max_size is set to 1000, batch_run_sleep is set to 1, the amount of
time it takes to fetch from the DB and queue work is N:

    max_job_rate = batch_max_size / (batch_run_sleep + N)

If N is, 0.10s, you can queue a maximum of 900 jobs per second from one
worker, or ~77.7 million jobs per day. Future versions should factor N into
the sleep, so watch this space for updates.

If you run 100 million jobs per day, but your peak job rate is 5000 jobs per
second, make sure you take that into account when setting up workers. It's
important to leave some overhead.

=head1 Job batching algorithm

QueueRunner attempts to queue jobs as slowly as possible. It starts with a low
number (say 50) per sleep. If it pulls back 50 jobs, during the next round it
will fetch 50 + 10% of batch_max_size. It will slowly increase until it hits
batch_max_size.

This helps prevent multiple QueueRunners from hogging each other's work,
keeping latency down as much as they can.

=cut

use strict;
use warnings;

use fields (
            'job_servers',
            'gearman_client',
            'dbd',
            'gearman_sockets',
            'batch_fetch_limit',
            'batch_run_sleep',
            'batch_max_size',
            'queue_watermark_depth',
            );

use Carp qw/croak/;
use Garivini::DB;
use Gearman::Client;
use IO::Socket;
use JSON;
use Data::Dumper qw/Dumper/;

# TODO: Make the "job" table name configurable:
# one dbid creates one connection, which is load balanced against N job tables
# need to test this, because in theory can get more throughput out of a single
# database by spreading the transaction locking anguish.

# Queue loading algorithm; pull minimum batch size, then grow up to the max
# size if queue isn't empty.
use constant MIN_BATCH_SIZE => 50;
use constant DEBUG => 0;

sub new {
    my Garivini::QueueRunner $self = shift;
    $self = fields::new($self) unless ref $self;
    my %args = @_;

    $self->{job_servers}     = {};
    # Gross direct socket connections until Gearman::Client gives us a way to
    # get queue status information more efficiently.
    $self->{gearman_sockets} = {};

    # TODO: Configuration verification!
    $self->{dbd}            = Garivini::DB->new(%args);
    $self->{job_servers}    = $args{job_servers};
    $self->{gearman_client} = Gearman::Client->new(
        job_servers => $args{job_servers});

    $self->{batch_fetch_limit} = MIN_BATCH_SIZE;
    $self->{batch_max_size} = $args{batch_max_size} || 1000;
    die "batch_max_size cannot be less than " . MIN_BATCH_SIZE
        if $self->{batch_max_size} < MIN_BATCH_SIZE;
    $self->{batch_run_sleep} = $args{batch_run_sleep} || 1;
    $self->{queue_watermark_depth} = $args{queue_watermark_depth} ||
        4000;

    return $self;
}

# Blindly pull jobs that are due up out of the database, to inject into
# gearmand.
sub _find_jobs_for_gearman {
    my $self   = shift;
    my $limit  = shift;
    my $queues = shift;

    # Fetch this round from a random queue.
    my ($dbh, $dbid) = $self->{dbd}->get_dbh();
    my @joblist = ();
    my $pulled  = 0;

    eval {
        $dbh->begin_work;
        my $query = qq{
            SELECT jobid, funcname, uniqkey, coalesce, run_after, arg,
            $dbid AS dbid, flag, failcount
            FROM job
            WHERE run_after <= UNIX_TIMESTAMP()
            ORDER BY run_after
            LIMIT $limit
            FOR UPDATE
        };
        my $sth = $dbh->prepare($query);
        $sth->execute;
        my $work = $sth->fetchall_hashref('jobid');
        # Claim the jobids for a while
        @joblist     = ();
        my @skiplist = ();
        # If queue is full, don't skip run_after as far
        for my $work (values %$work) {
            $pulled++;
            if (exists $queues->{$work->{funcname}}
                && $queues->{$work->{funcname}} >
                $self->{queue_watermark_depth}) {
                push(@skiplist, $work->{jobid});
            } else {
                push(@joblist, $work);
            }
        }
        my $idlist   = join(',', map { $_->{jobid} }  @joblist);
        my $skiplist = join(',', @skiplist);

        # TODO: time adjustment should be configurable
        $dbh->do("UPDATE job SET run_after = UNIX_TIMESTAMP() + 1000 "
            . "WHERE jobid IN ($idlist)") if $idlist;
        $dbh->do("UPDATE job SET run_after = UNIX_TIMESTAMP() + 60 "
            . "WHERE jobid IN ($skiplist)") if $skiplist;
        $dbh->commit;
    };
    # Doesn't really matter what the failure is. Deadlock? We'll try again
    # later. Dead connection? get_dbh() should be validating.
    # TODO: Make sure get_dbh is validating, or set a flag here on error which
    # triggers get_dbh to run a $dbh->ping next time.
    if ($@) {
        DEBUG && print STDERR "DB Error pulling from queue: $@";
        eval { $dbh->rollback };
        return ();
    }

    return (\@joblist, $pulled);
}

# Fetch gearmand status (or is there a better command?)
# Look for any functions which are low enough in queue to get more injections.
sub _check_gearman_queues {
    my $self    = shift;
    return {} if $self->{queue_watermark_depth} == 0;
    my $servers = $self->{job_servers};
    my $socks   = $self->{gearman_sockets};
    my %queues  = ();

    # Bleh. nasty IO::Socket code to connect to the gearmand's and run "status".
    for my $server (@$servers) {
        my $sock = $socks->{$server} || undef;
        unless ($sock) {
            $sock = IO::Socket::INET->new(PeerAddr => $server,
                Timeout => 3);
            next unless $sock;
            $socks->{$server} = $sock;
        }
        eval {
            print $sock "status\r\n";

            while (my $line = <$sock>) {
                chomp $line;
                last if $line =~ m/^\./;
                my @fields = split(/\s+/, $line);
                $queues{$fields[0]} += $fields[1];
            }
        };
        if ($@) {
            # As usual, needs more complete error handling.
            $socks->{$server} = undef;
        }
    }

    return \%queues;
}

# Send all jobs via background tasks.
# We don't care about the response codes, as we rely on the gearman workers to
# issue the database delete.
sub _send_jobs_to_gearman {
    my $self = shift;
    my $jobs = shift;

    my $client = $self->{gearman_client};

    for my $job (@$jobs) {
        my $funcname;
        $job->{flag} ||= 'shim';
        if ($job->{flag} eq 'shim') {
            $funcname = $job->{funcname};
        } elsif ($job->{flag} eq 'controller') {
            $funcname = 'run_queued_job';
        } else {
            die "Unknown flag state $job->{flag}";
        }
        my %opts = ();
        $opts{uniq} = $job->{uniqkey} if $job->{uniqkey};
        $client->dispatch_background($funcname, \encode_json($job), \%opts);
    }
}

# This isn't your typical worker, as in it doesn't register as a gearman
# worker at all. It's a sideways client.
# TODO; split into work/work_once ?
sub work {
    my $self = shift;

    while (1) {
        my $queues = $self->_check_gearman_queues;
        my ($jobs, $pulled) = $self->_find_jobs_for_gearman($self->{batch_fetch_limit},
            $queues);
        if (!defined $jobs) {
            sleep $self->{batch_run_sleep}; next;
        }
        my $job_count = scalar @$jobs;
        DEBUG && print STDERR "Pulled $pulled new jobs from DB\n";
        DEBUG && print STDERR "Sending $job_count jobs to gearmand\n";
        $self->_send_jobs_to_gearman($jobs);

        # Yeah I know. Lets play a word-flip game.
        my $max_batch_size = $self->{batch_max_size};
        if ($job_count >= $self->{batch_fetch_limit}) {
            $self->{batch_fetch_limit} += ($max_batch_size * 0.1);
            $self->{batch_fetch_limit} = $max_batch_size
                if $self->{batch_fetch_limit} >= $max_batch_size;
        } else {
            $self->{batch_fetch_limit} -= ($max_batch_size * 0.05);
            $self->{batch_fetch_limit} = MIN_BATCH_SIZE
                if $self->{batch_fetch_limit} <= MIN_BATCH_SIZE;
        }

        DEBUG && print STDERR "Sent, sleeping\n";
        # Sleep for configured amount of time.
        # TODO: Use the select microsleep hack?
        sleep $self->{batch_run_sleep};
    }
}

1;
