package Garivini::Controller;

=head1 NAME

Garivini::Controller - Gearman worker for executing Garivini jobs

=head1 DESCRIPTION

Picks up asynchronously submitted Garivini jobs, then synchronously submits
them back through Gearman to a real worker.

Once the worker completes the job, it is removed from the Garivini DB or
rescheduled for a future retry.

You need to run as many Controller workers as you have workers for other jobs.

NOTE that this is an optional worker for providing job routing via pure
Gearman calls, or providing low latency. If using L<Garivini::Client>
directly, only L<Garivini::QueueRunner> workers are needed.

=head1 SYNOPSIS

    my $worker = Garivini::Controller->new(dbs => {
        1 => { id => 1, dsn => 'DBI:mysq:job:host=127.0.0.1', user => 'job',
            pass => 'job' } },
        job_servers => ['127.0.0.1']);
    $worker->work;

=cut

use strict;
use warnings;
use fields ('dbd',
            'sm_client',
            'gm_client',
            'job_servers',
           );

use Garivini::DB;
use Garivini::Client;
use Gearman::Client;
use Gearman::Worker;
use JSON;

use constant DEBUG => 0;

sub new {
    my Garivini::Controller $self = shift;
    $self = fields::new($self) unless ref $self;
    my %args = @_;

    $self->{job_servers} = delete $args{job_servers};
    $self->{sm_client} = Garivini::Client->new(%args);
    $self->{gm_client} = Gearman::Client->new(
        job_servers => $self->{job_servers});

    return $self;
}

sub work {
    my $self = shift;
    my $worker = Gearman::Worker->new(job_servers => $self->{job_servers});
    $worker->register_function('run_queued_job' => sub {
        $self->run_queued_job(@_);
    });
    $worker->work while 1; # redundant.
}

sub run_queued_job {
    my $self = shift;
    my $gm_job  = shift;

    my $sm_client = $self->{sm_client};
    my $gm_client = $self->{gm_client};

    my $sm_job = decode_json(${$gm_job->argref});
    DEBUG && warn "Got a job $sm_job->{funcname}\n";

    # NOTE: This passes the full job around, instead of initially passing a
    # handle and SELECT'ing it back from the DB here. Need to ensure this is
    # worth the tradeoff.
    my $res = $gm_client->do_task($sm_job->{funcname}, $gm_job->arg);
    DEBUG && warn "Gearman do_task result is $res\n";

    if (defined $res) {
        $sm_client->complete_job($sm_job);
    } else {
        # TODO: Be more intelligent about when a failure requires a retry, vs
        # when it's permanently dead?
        $sm_client->failed_job($sm_job);
    }

    return;
}

1;
