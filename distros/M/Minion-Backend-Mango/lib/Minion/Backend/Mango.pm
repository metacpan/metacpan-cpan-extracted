package Minion::Backend::Mango;
use Mojo::Base 'Minion::Backend';

our $VERSION = '1.02';

use Mango;
use Mango::BSON qw(bson_oid bson_time bson_doc);
use Sys::Hostname 'hostname';
use Time::HiRes 'time';

has 'mango';
has jobs          => sub { $_[0]->mango->db->collection($_[0]->prefix . '.jobs') };
has notifications => sub { $_[0]->mango->db->collection($_[0]->prefix . '.notifications') };
has prefix        => 'minion';
has workers       => sub { $_[0]->mango->db->collection($_[0]->prefix . '.workers') };

sub broadcast {
  my ($self, $command, $args, $ids) = (shift, shift, shift || [], shift || []);

  my $opts = @$ids ? {_id => {'$in' => $ids}} : {};
  return !!$self->workers->update($opts, {'$push' => {inbox => [$command, @$args]}}, {multi => 1})->{n};
}

sub dequeue {
  my ($self, $wid, $wait, $options) = @_;

  $self->_notifications;

  my $end = time + $wait;
  do {
    if (my $job = $self->_try($wid, $options)) { return $self->_job_info($job); }
    $self->_await;
  } while time < $end;

  return $self->_job_info($self->_try($wid, $options));
}

sub enqueue {
  my ($self, $task) = (shift, shift);
  my $args    = shift // [];
  my $options = shift // {};

  $self->_notifications;

  my $doc = {
    args     => $args,
    attempts => $options->{attempts} // 1,
    created  => bson_time,
    delayed  => bson_time($options->{delay} ? (time + $options->{delay}) * 1000 : 1),
    priority => $options->{priority} // 0,
    queue    => $options->{queue}    // 'default',
    retries  => 0,
    state    => 'inactive',
    task     => $task
  };

  my $oid = $self->jobs->insert($doc);
  $self->notifications->insert({c => 'created'});
  return $oid;
}

sub fail_job { shift->_update(1, @_) }

sub finish_job { shift->_update(0, @_) }

sub job_info {
  $_[0]->_job_info($_[0]->jobs->find_one(bson_oid($_[1])));
}

sub list_jobs {
  my ($self, $skip, $limit, $options) = @_;

  my $cursor = $self->jobs->find({state => {'$exists' => \1}});
  for (qw/state task queue/) {
    $cursor->query->{$_} = $options->{$_} if $options->{$_};
  }
  $cursor->sort({_id => -1})->skip($skip)->limit($limit);

  return [map { $self->_job_info($_) } @{$cursor->all}];
}

sub list_workers {
  my ($self, $skip, $limit) = @_;
  my $cursor = $self->workers->find({pid => {'$exists' => \1}});
  $cursor->sort({_id => -1})->skip($skip)->limit($limit);
  return [map { $self->_worker_info($_) } @{$cursor->all}];
}

sub new { shift->SUPER::new(mango => Mango->new(@_)) }

sub receive {
  my ($self, $id) = @_;

  my $doc = $self->workers->find_and_modify({query => {_id => $id}, update => {'$set' => {inbox => []}}});
  return $doc->{inbox} // [];
}

sub register_worker {
  my ($self, $id, $options) = (shift, shift, shift || {});

  my $status = $options->{status} // {};
  return $id
    if $id
    && $self->workers->find_and_modify(
    {query => {_id => $id}, update => {'$set' => {notified => bson_time, status => $status}}});

  $self->jobs->ensure_index(bson_doc(state => 1, delayed => 1, task => 1, queue => 1));
  return $self->workers->insert(
    {host => hostname, pid => $$, started => bson_time, notified => bson_time, status => $status});
}

sub remove_job {
  my ($self, $oid) = @_;
  my $doc = {_id => $oid, state => {'$in' => [qw(failed finished inactive)]}};
  return !!$self->jobs->remove($doc)->{n};
}

sub repair {
  my $self   = shift;
  my $minion = $self->minion;

  # Check worker registry
  my $workers = $self->workers;
  $workers->remove({notified => {'$lt' => bson_time((time - $minion->missing_after) * 1000)}});

  # Abandoned jobs
  my $jobs = $self->jobs;
  my $cursor = $jobs->find({state => 'active'}, {_id => 1, retries => 1, worker => 1});
  while (my $job = $cursor->next) {
    $self->fail_job($job->{_id}, $job->{retries}, 'Worker went away')
      unless $workers->find_one($job->{worker});
  }

  # Old jobs
  $jobs->remove(
    {state => 'finished', finished => {'$lt' => bson_time((time - $minion->remove_after) * 1000)}});
}

sub reset {
  my $self = shift;

  $_->options && $_->drop for $self->workers, $self->jobs, $self->notifications;
  delete $self->{capped};
}

sub retry_job {
  my ($self, $oid, $retries) = (shift, shift, shift);
  my $options = shift // {};

  my $query = {_id => $oid, retries => $retries, state => {'$in' => [qw(failed finished inactive)]}};
  my $update = {
    '$inc' => {retries => 1},
    '$set' => {
      retried => bson_time,
      state   => 'inactive',
      delayed => bson_time($options->{delay} ? (time + $options->{delay}) * 1000 : 1),
      (defined $options->{priority} ? (priority => $options->{priority}) : ()),
      (defined $options->{queue}    ? (queue    => $options->{queue})    : ())
    }
  };

  return !!$self->jobs->update($query, $update)->{n};
}

sub stats {
  my $self = shift;

  my $jobs    = $self->jobs;
  my $active  = @{$jobs->find({state => 'active'})->distinct('worker')};
  my $workers = $self->workers;
  my $all     = $workers->find->count;
  my $stats   = {active_workers => $active, inactive_workers => $all - $active};
  $stats->{"${_}_jobs"} = $jobs->find({state => $_})->count for qw(active failed finished inactive);
  $stats->{delayed_jobs} = $jobs->find({state => 'inactive', delayed => {'$gt' => bson_time}})->count;
  return $stats;
}

sub unregister_worker { shift->workers->remove(shift) }

sub worker_info { $_[0]->_worker_info($_[0]->workers->find_one($_[1])) }

sub _await {
  my $self = shift;

  my $last = $self->{last} //= bson_oid;
  my $cursor
    = $self->notifications->find({_id => {'$gt' => $last}, c => 'created'})->tailable(1)->await_data(1);
  return undef unless my $doc = $cursor->next || $cursor->next;
  $self->{last} = $doc->{_id};
  return 1;
}

sub _job_info {
  my $self = shift;

  return undef unless my $job = shift;
  return {
    args     => $job->{args},
    attempts => $job->{attempts},
    created  => $job->{created} ? $job->{created}->to_epoch : undef,
    delayed  => $job->{delayed} ? $job->{delayed}->to_epoch : undef,
    finished => $job->{finished} ? $job->{finished}->to_epoch : undef,
    id       => $job->{_id},
    priority => $job->{priority},
    queue    => $job->{queue},
    result   => $job->{result},
    retried  => $job->{retried} ? $job->{retried}->to_epoch : undef,
    retries => $job->{retries} // 0,
    started => $job->{started} ? $job->{started}->to_epoch : undef,
    state   => $job->{state},
    task    => $job->{task}
  };
}

sub _notifications {
  my $self = shift;

  # We can only await data if there's a document in the collection
  $self->{capped} ? return : $self->{capped}++;
  my $notifications = $self->notifications;
  return if $notifications->options;
  $notifications->create({capped => \1, size => 1048576, max => 128});
  $notifications->insert({});
}

sub _try {
  my ($self, $wid, $options) = @_;

  my $doc = {
    query => bson_doc(
      state   => 'inactive',
      delayed => {'$lt' => bson_time},
      task    => {'$in' => [keys %{$self->minion->tasks}]},
      queue   => {'$in' => $options->{queues} || ['default']}
    ),
    fields => bson_doc(args     => 1,  retries => 1, task => 1),
    sort   => bson_doc(priority => -1, created => 1),
    update => {'$set' => {started => bson_time, state => 'active', worker => $wid}},
    new    => 1
  };

  return $self->jobs->find_and_modify($doc);
}

sub _update {
  my ($self, $fail, $oid, $retries, $result) = @_;

  my $update = {finished => bson_time, result => $result, state => $fail ? 'failed' : 'finished'};
  my $query = {_id => $oid, retries => $retries, state => 'active'};

  my $opts = {query => $query, update => {'$set' => $update}, fields => {attempts => 1}};
  return undef unless my $job = $self->jobs->find_and_modify($opts);
  return 1 if !$fail || (my $attempts = $job->{attempts}) == 1;
  return 1 if $retries >= ($attempts - 1);
  my $delay = $self->minion->backoff->($retries);
  return $self->retry_job($oid, $retries, {delay => $delay});
}

sub _worker_info {
  my $self = shift;

  return undef unless my $worker = shift;
  my $cursor = $self->jobs->find({state => 'active', worker => $worker->{_id}});
  return {
    host     => $worker->{host},
    id       => $worker->{_id},
    jobs     => [map { $_->{_id} } @{$cursor->all}],
    pid      => $worker->{pid},
    started  => $worker->{started}->to_epoch,
    notified => $worker->{notified}->to_epoch
  };
}

1;

=encoding utf8

=head1 NAME

Minion::Backend::Mango - Mango backend for Minion

=head1 SYNOPSIS

  use Minion::Backend::Mango;

  my $backend = Minion::Backend::Mango->new('mongodb://127.0.0.1:27017');

=head1 DESCRIPTION

L<Minion::Backend::Mango> is a highly scalable L<Mango> backend for L<Minion>.

=head1 ATTRIBUTES

L<Minion::Backend::Mango> inherits all attributes from L<Minion::Backend> and
implements the following new ones.

=head2 mango

  my $mango = $backend->mango;
  $backend  = $backend->mango(Mango->new);

L<Mango> object used to store collections.

=head2 jobs

  my $jobs = $backend->jobs;
  $backend = $backend->jobs(Mango::Collection->new);

L<Mango::Collection> object for C<jobs> collection, defaults to one based on L</"prefix">.

=head2 notifications

  my $notifications = $backend->notifications;
  $backend          = $backend->notifications(Mango::Collection->new);

L<Mango::Collection> object for C<notifications> collection, defaults to one based on L</"prefix">.

=head2 prefix

  my $prefix = $backend->prefix;
  $backend   = $backend->prefix('foo');

Prefix for collections, defaults to C<minion>.

=head2 workers

  my $workers = $backend->workers;
  $backend    = $backend->workers(Mango::Collection->new);

L<Mango::Collection> object for C<workers> collection, defaults to one based on L</"prefix">.

=head1 METHODS

L<Minion::Backend::Mango> inherits all methods from L<Minion::Backend> and implements the following new ones.

=head2 dequeue

  my $job_info = $backend->dequeue($worker_id, 0.5);
  my $job_info = $backend->dequeue($worker_id, 0.5, {queues => ['default']});

Wait for job, dequeue it and transition from C<inactive> to C<active> state or
return C<undef> if queue was empty.

These options are currently available:

=over 2

=item queues

  queues => ['important']

One or more queues to dequeue jobs from, defaults to C<default>.

=back

=head2 enqueue

  my $job_id = $backend->enqueue('foo');
  my $job_id = $backend->enqueue(foo => [@args]);
  my $job_id = $backend->enqueue(foo => [@args] => {priority => 1});

Enqueue a new job with C<inactive> state. These options are currently available:

=over 2

=item attempts

  attempts => 25

Number of times performing this job will be attempted, defaults to C<1>.

=item delay

  delay => 10

Delay job for this many seconds from now.

=item priority

  priority => 5

Job priority, defaults to C<0>.

=item queue

  queue => 'important'

Queue to put job in, defaults to C<default>.

=back

=head2 fail_job

  my $bool = $backend->fail_job($job_id);
  my $bool = $backend->fail_job($job_id, 'Something went wrong!');

Transition from C<active> to C<failed> state.

=head2 finish_job

  my $bool = $backend->finish_job($job_id);

Transition from C<active> to C<finished> state.

=head2 job_info

  my $info = $backend->job_info($job_id);

Get information about a job or return C<undef> if job does not exist.

=head2 list_jobs

  my $batch = $backend->list_jobs($skip, $limit);
  my $batch = $backend->list_jobs($skip, $limit, {state => 'inactive'});

Returns the same information as L</"job_info"> but in batches.

These options are currently available:

=over 2

=item queue

  queue => 'important'

List only jobs in this queue.

=item state

  state => 'inactive'

List only jobs in this state.

=item task

  task => 'test'

List only jobs for this task.

=back

=head2 list_workers

  my $batch = $backend->list_workers($skip, $limit);

Returns the same information as L</"worker_info"> but in batches.

=head2 new

  my $backend = Minion::Backend::Mango->new('mongodb://127.0.0.1:27017');

Construct a new L<Minion::Backend::Mango> object.

=head2 register_worker

  my $worker_id = $backend->register_worker;
  my $worker_id = $backend->register_worker($worker_id);

Register worker or send heartbeat to show that this worker is still alive.

=head2 remove_job

  my $bool = $backend->remove_job($job_id);

Remove C<failed>, C<finished> or C<inactive> job from queue.

=head2 repair

  $backend->repair;

Repair worker registry and job queue if necessary.

=head2 reset

  $backend->reset;

Reset job queue.

=head2 retry_job

  my $bool = $backend->retry_job($job_id);
  my $bool = $backend->retry_job($job_id, {delay => 10});

Transition from C<failed> or C<finished> state back to C<inactive>, already
C<inactive> jobs may also be retried to change options.

These options are currently available:

=over 2

=item delay

  delay => 10

Delay job for this many seconds (from now).

=item priority

  priority => 5

Job priority.

=item queue

  queue => 'important'

Queue to put job in.

=back

=head2 stats

  my $stats = $backend->stats;

Get statistics for jobs and workers.

=head2 unregister_worker

  $backend->unregister_worker($worker_id);

Unregister worker.

=head2 worker_info

  my $info = $backend->worker_info($worker_id);

Get information about a worker or return C<undef> if worker does not exist.

=head1 AUTHOR

Andrey Khozov E<lt>avkhozov@gmail.comE<gt>

Sebastian Riedel E<lt>sri@cpan.orgE<gt>

=head1 LICENSE

Copyright (C) 2014, Sebastian Riedel.

Copyright (C) 2015-2016, Andrey Khozov.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Minion>, L<Mango>, L<http://mojolicio.us>.

=cut
