package Garivini::Injector;

=head1 NAME

Garivini::Injector - Synchronously inject jobs into Garivini

=head1 DESCRIPTION

Gearman worker for submitting jobs into Garivini via Gearman. Clients should
synchronously send jobs through this worker, which are then stored into the
Garivini DB before returning to the client.

Any actual job execution is run asynchronously, by way of a
L<Garivini::Controller> worker.

Jobs may be submitted with any language. You need to run enough of these
workers so jobs may be quickly pulled out and queued into the database.

NOTE that this worker is only required if low latency is desired, or you wish
to use a pure Gearman client. If using L<Garivini::Client> directly, only
L<Garivini::QueueRunner> workers are needed.

=head1 SYNOPSIS

    my $worker = Garivini::Controller->new(dbs => {
        1 => { id => 1, dsn => 'DBI:mysq:job:host=127.0.0.1', user => 'job',
            pass => 'job' } },
        job_servers => ['127.0.0.1'],
        queue_watermark_depth => 4000);
    $worker->work;

=head1 OPTIONS

=over

=item queue_watermark_depth

UNIMPLEMENTED! After writing a job to the database, but before submitting it
back into Gearman for execution, the queue depth for that particular function
is checked. If there are more than queue_watermark_depth jobs presently
waiting for execution, the job will not be directly executed.

Instead, L<Garivini::QueueRunner> will queue the job for execution after
Gearman's queues have depleted enough. Use this to help avoid running Gearmand
out of memory.

Set to 0 to disable.

=back

=cut

use strict;
use warnings;

use Garivini::DB;
use Garivini::Client;
use Gearman::Worker;
use Gearman::Client;
use JSON;
use Data::Dumper qw/Dumper/;

use fields (
            'job_servers',
            'sm_client',
            'gm_client',
            'last_queue_check',
            'queues',
            'queue_watermark_depth',
           );

sub new {
    my Garivini::Injector $self = shift;
    $self = fields::new($self) unless ref $self;
    my %args = @_;

    $self->{job_servers} = delete $args{job_servers};

    $self->{sm_client} = Garivini::Client->new(%args);
    $self->{gm_client} = Gearman::Client->new(
        job_servers => $self->{job_servers});
    $self->{last_queue_check} = 0;
    $self->{queues} = {};
    $self->{queue_watermark_depth} = $args{queue_watermark_depth}
        || 0;

    return $self;
}

sub work {
    my $self = shift;
    my $worker = Gearman::Worker->new(job_servers => $self->{job_servers});
    $worker->register_function(inject_jobs => sub {
        $self->inject_jobs(@_);
    });
    $worker->work while 1; # redundant.
}

# For bonus points, submit jobs in this method with a run_after noted as
# "locked", so the client code can pre-adjust it and not be forced to
# re-encode.
# TODO: If $job is an arrayref of other jobs, do a multi insert, but don't
# inject directly into run_queued_job. QueueRunner will pick them back out
# with the jobids intact.
sub inject_jobs {
    my $self = shift;
    my $job  = shift;

    my $queues = $self->{queues};
    my $args = decode_json(${$job->argref});
    my $run_job = 1;
    if ($queues->{$args->{funcname}} && $queues->{$args->{funcname}} >
        $self->{queue_watermark_depth}) {
        $run_job = 0;
    }

    # TODO: Uhh if $job->{arg} was a cuddled JSON blob, did this just decode
    # that? Easy enough to test and fix, but I'm tired :P
    $args->{run_after} = ($run_job && exists $args->{run_after}) ? $args->{run_after}
        : 1000;
    $args->{flag} = 'controller';
    my ($jobid, $dbid) = $self->{sm_client}->insert_job(%$args);

    $args->{jobid} = $jobid;
    $args->{dbid}  = $dbid;
    if ($run_job) {
        my %opts = ();
        $opts{uniq} = $args->{uniqkey} if $args->{uniqkey};
        $self->{gm_client}->dispatch_background('run_queued_job',
            \encode_json($args), \%opts);
    }

    if ($self->{last_queue_check} < time() - 60) {
        $self->{last_queue_check} = time();
        $self->{queues} = $self->check_gearman_queues;
    }

    return;
}

# TODO: Copy/paste code from QueueRunner until Gearman::Client has a thing
# for this.
sub check_gearman_queues {
    my $self = shift;
    return {} if $self->{queue_watermark_depth} == 0;
    return {};
}

1;
