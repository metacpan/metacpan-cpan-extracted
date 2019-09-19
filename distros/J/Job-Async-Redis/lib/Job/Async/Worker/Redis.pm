package Job::Async::Worker::Redis;

use strict;
use warnings;

use parent qw(Job::Async::Worker);

our $VERSION = '0.004'; # VERSION

=head1 NAME

Job::Async::Worker::Redis - L<Net::Async::Redis> worker implementation for L<Job::Async::Worker>

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use curry::weak;
use Syntax::Keyword::Try;
use Future::AsyncAwait;

use Job::Async::Utils;
use Future::Utils qw(repeat);
use JSON::MaybeUTF8 qw(:v1);
use Log::Any qw($log);

use Net::Async::Redis;

=head2 incoming_job

Source for jobs received from the C<< BRPOP(LPUSH) >> queue wait.

=cut

sub incoming_job {
    my ($self) = @_;
    $self->{incoming_job} //= do {
        die 'needs to be part of a loop' unless $self->loop;
        my $src = $self->ryu->source;
        $src->map($self->curry::weak::on_job_received)->map('retain')->retain;
        $src
    }
}

=head2 on_job_received

Called for each job that's received.

=cut

async sub on_job_received {
    my ($self, $id) = (shift, @$_);
    try {
        my ($queue) = $self->pending_queues;

        $log->debugf('Received job %s', $id);
        if(exists $self->{pending_jobs}{$id}) {
            $log->errorf("Already have job %s", $id);
            die 'Duplicate job ID';
        } else {
            undef $self->{pending_jobs}{$id};
        }

        my $job_count = 0 + keys %{$self->{pending_jobs}};
        $log->debugf("Current job count is %d", $job_count);
        $self->trigger;
        my ($items) = await $self->redis->hgetall('job::' . $id);
        $self->redis->hmset(
            'job::' . $id,
            _started => Time::HiRes::time()
        )->retain;
        my %data = @$items;
        my $result = delete $data{result};
        $log->debugf('Original job data is %s', \%data);
        $self->{pending_jobs}{$id} = my $job = Job::Async::Job->new(
            data   => Job::Async::Job->structured_data(\%data),
            id     => $id,
            future => my $f = $self->loop->new_future,
        );

        $log->debugf('Job content is %s', { map { $_ => $job->{$_} } qw(data id) });
        $f->on_done(sub {
            my ($rslt) = @_;
            $log->debugf("Result was %s", $rslt);
            my $code = sub {
                my $tx = shift;
                try {
                    delete $self->{pending_jobs}{$id};
                    $log->tracef('Removing job from processing queue');
                    return Future->needs_all(
                        map {
                            $_->on_ready(sub {
                                my $f = shift;
                                $log->tracef('ready for %s - %s', $f->label, $f->state);
                            });
                        }
                        $tx->hmset(
                            'job::' . $id,
                            _processed => Time::HiRes::time(),
                            result => ref($rslt) ? 'J' . encode_json_utf8($rslt) : 'T' . $rslt
                        ),
                        $tx->publish('client::' . $data{_reply_to}, $id),
                        $tx->lrem(
                            $self->prefixed_queue($self->processing_queue) => 1,
                            $id
                        ),
                    )
                } catch {
                    $log->errorf("Failed due to %s", $@);
                    return Future->fail($@, redis => $self->id, $id);
                }
            };
            (
                $self->use_multi
                ? $self->redis->multi($code)
                : $code->($self->redis)
            )->on_ready($self->curry::weak::trigger)
              ->on_fail(sub { $log->errorf('Failed to update Redis status for job %s - %s', $id, shift); })
              ->retain;
        });
        $f->on_ready($self->curry::weak::trigger);
        if(my $timeout = $self->timeout) {
            Future->needs_any(
                $f,
                $self->loop->timeout_future(after => $timeout)->on_fail(sub {
                    local @{$log->{context}}{qw(worker_id job_id)} = ($self->id, $id);
                    $log->errorf("Timeout but already completed with %s", $f->state) if $f->is_ready;
                    $f->fail('timeout')
                })
            )->retain;
        }
        $self->jobs->emit($job);
        return $f;
    } catch {
        $log->errorf("Unable to process received job %s - %s", $id, $@);
    }
}

sub use_multi { shift->{use_multi} }

sub prefix { shift->{prefix} //= 'jobs' }

=head2 pending_queues

Note that L<reliable mode|Job::Async::Redis/reliable> only
supports a single queue, and will fail if you attempt to start with multiple
queues defined.

=cut

sub pending_queues { @{ shift->{pending_queues} ||= [qw(pending)] } }

=head2 processing_queue

=cut

sub processing_queue { shift->{processing_queue} //= 'processing' }

=head2 start

=cut

sub start {
    my ($self) = @_;

    $self->trigger;
}

=head2 stop

Requests to stop processing.

Returns a future which will complete when all currently-processing jobs have
finished.

=cut

sub stop {
    my ($self) = @_;
    my $pending = 0 + keys %{$self->{pending_jobs}};
    if(!$pending && $self->{awaiting_job}) {
        return $self->stopping_future->done;
    }
    # else, either a job is being processed, or there are pending ones.
    # sub trigger will recheck
    return $self->stopping_future;
}

sub stopping_future {
    my ($self) = @_;
    $self->{stopping_future} ||= $self->loop->new_future->set_label('Job::Async::Worker::Redis shutdown');
}

sub queue_redis {
    my ($self) = @_;
    unless($self->{queue_redis}) {
        $self->add_child(
            $self->{queue_redis} = Net::Async::Redis->new(
                uri => $self->uri,
            )
        );
        $self->{queue_redis}->connect;
    }
    return $self->{queue_redis};
}

sub redis {
    my ($self) = @_;
    unless($self->{redis}) {
        $self->add_child(
            $self->{redis} = Net::Async::Redis->new(
                uri => $self->uri,
            )
        );
        $self->{redis}->connect;
    }
    return $self->{redis};
}

sub prefixed_queue {
    my ($self, $q) = @_;
    return $q unless length(my $prefix = $self->prefix);
    return join '::', $self->prefix, $q;
}

sub trigger {
    my ($self) = @_;
    local @{$log->{context}}{qw(worker_id queue)} = ($self->id, my ($queue) = $self->pending_queues);
    try {
        my $pending = 0 + keys %{$self->{pending_jobs}};
        $log->tracef('Trigger called with %d pending tasks, %d max', $pending, $self->max_concurrent_jobs);
        return if $pending >= $self->max_concurrent_jobs;

        return $self->{awaiting_job} //= do {
            $log->debugf('Awaiting job on %s', $queue);
            Future->wait_any(
                # If this is cancelled, we don't retrigger. Failure or success should retrigger as usual.
                $self->queue_redis->brpoplpush(
                    $self->prefixed_queue($queue) => $self->prefixed_queue($self->processing_queue),
                    $self->job_poll_interval
                )->on_done(sub {
                    my ($id, $queue, @details) = @_;
                    try {
                        $log->tracef('And we have an event on %s', $queue);
                        if($id) {
                            $log->tracef('Had task from queue, pending now %d', 0 + keys %{$self->{pending_jobs}});
                            $self->incoming_job->emit([ $id, $queue ]);
                        } else {
                            $log->tracef('No ID, full details were %s - maybe timeout?', join ' ', $id // (), $queue // (), @details);
                        }
                    } catch {
                        $log->errorf("Failed to retrieve and process job: %s", $@);
                    }
                    $self->loop->later($self->curry::weak::trigger) unless $self->stopping_future->is_ready;
                })->on_fail(sub {
                    my $failure = shift;
                    $log->errorf("Failed to retrieve job from redis: %s", $failure);
                    $self->loop->later($self->curry::weak::trigger) unless $self->stopping_future->is_ready;
                }),
                $self->stopping_future->without_cancel
            )->on_ready(sub {
                delete $self->{awaiting_job};
            });
        };
    } catch {
        $log->errorf('Failed to trigger job handling on %s - %s', $queue, $@);
    }
    return;
}

=head2 max_concurrent_jobs

Number of jobs to process in parallel. Defaults to 1.

=cut

sub max_concurrent_jobs { shift->{max_concurrent_jobs} //= 1 }

=head2 job_poll_interval

Polling interval (e.g. for C<BRPOPLPUSH> in C<reliable> mode), in seconds.

Defaults to 3 seconds.

=cut

sub job_poll_interval { shift->{job_poll_interval} //= 3 }

sub uri { shift->{uri} }

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(uri max_concurrent_jobs prefix mode processing_queue use_multi job_poll_interval)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }

    if(exists $args{pending_queues}) {
        if(my $queues = $args{pending_queues}) {
            die 'Only a single queue is supported in reliable mode' if $self->mode eq 'reliable' and @$queues > 1;
            $self->{pending_queues} = $queues;
        } else {
            delete $self->{pending_queues}
        }
    }
    return $self->next::method(%args);
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2019. Licensed under the same terms as Perl itself.

