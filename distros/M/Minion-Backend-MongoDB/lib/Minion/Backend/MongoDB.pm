package Minion::Backend::MongoDB;
use Mojo::Base 'Minion::Backend';

our $VERSION = '0.97';

use boolean;
use DateTime;
use Mojo::URL;
use MongoDB::OID;
use MongoDB;
use Sys::Hostname 'hostname';
use Tie::IxHash;
use Time::HiRes 'time';

has 'mongodb';
has jobs          => sub { $_[0]->mongodb->coll($_[0]->prefix . '.jobs') };
has notifications => sub { $_[0]->mongodb->coll($_[0]->prefix . '.notifications') };
has prefix        => 'minion';
has workers       => sub { $_[0]->mongodb->coll($_[0]->prefix . '.workers') };

sub dequeue {
  my ($self, $oid) = @_;

  # Capped collection for notifications
  $self->_notifications;

  # Await notifications
  $self->_await;
  my $job = $self->_try($oid);

  return undef unless $self->_job_info($job);
  return {args => $job->{args}, id => $job->{_id}, task => $job->{task}};
}

sub enqueue {
  my ($self, $task) = (shift, shift);
  my $args    = shift // [];
  my $options = shift // {};

  # Capped collection for notifications
  $self->_notifications;

  my $doc = {
    args    => $args,
    created => DateTime->from_epoch(epoch => time),
    delayed => DateTime->from_epoch(epoch => $options->{delay} ? time + $options->{delay} : 1),
    priority => $options->{priority} // 0,
    state    => 'inactive',
    task     => $task
  };

  my $oid = $self->jobs->insert($doc);
  $self->notifications->insert({c => 'created'});
  return $oid;
}

sub fail_job { shift->_update(1, @_) }

sub finish_job { shift->_update(0, @_) }

sub job_info { $_[0]->_job_info($_[0]->jobs->find_one({_id => MongoDB::OID->new(value => "$_[1]")})); }

sub list_jobs {
  my ($self, $skip, $limit, $options) = @_;

  my $query = {state => {'$exists' => true}};
  $query->{state} = $options->{state} if $options->{state};
  $query->{task}  = $options->{task}  if $options->{task};

  my $cursor = $self->jobs->find($query);
  $cursor->sort({_id => -1})->skip($skip)->limit($limit);

  return [map { $self->_job_info($_) } $cursor->all];
}

sub list_workers {
  my ($self, $skip, $limit) = @_;
  my $cursor = $self->workers->find({pid => {'$exists' => true}});
  $cursor->sort({_id => -1})->skip($skip)->limit($limit);
  return [map { $self->_worker_info($_) } $cursor->all];
}

sub new {
  my ($class, $url) = @_;
  my $client = MongoDB::MongoClient->new(host => $url);
  my $db = $client->db($client->db_name);
  return $class->SUPER::new(mongodb => $db);
}

sub register_worker {
  my ($self, $id) = @_;

  return $id
    if $id
    && $self->workers->find_and_modify(
    {query => {_id => $id}, update => {'$set' => {notified => DateTime->from_epoch(epoch => time)}}});

  $self->jobs->ensure_index(Tie::IxHash->new(state => 1, delayed => 1, task => 1));
  $self->workers->insert(
    { host     => hostname,
      pid      => $$,
      started  => DateTime->from_epoch(epoch => time),
      notified => DateTime->from_epoch(epoch => time)
    }
  );
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
  $workers->remove({notified => {'$lt' => DateTime->from_epoch(epoch => time - $minion->missing_after)}});

  # Abandoned jobs
  my $jobs = $self->jobs;
  my $cursor = $jobs->find({state => 'active'});
  while (my $job = $cursor->next) {
    $jobs->save(
      { %$job,
        finished => DateTime->from_epoch(epoch => time),
        state    => 'failed',
        result   => 'Worker went away'
      }
    ) unless $workers->find_one({_id => $job->{worker}});
  }

  # Old jobs
  $jobs->remove(
    {state => 'finished', finished => {'$lt' => DateTime->from_epoch(epoch => time - $minion->remove_after)}}
  );
}

sub reset { $_->drop for $_[0]->workers, $_[0]->jobs }

sub retry_job {
  my ($self, $oid) = (shift, shift);
  my $options = shift // {};

  my $query = {_id => $oid, state => {'$in' => [qw(failed finished)]}};
  my $update = {
    '$inc' => {retries => 1},
    '$set' => {
      retried => DateTime->from_epoch(epoch => time),
      state   => 'inactive',
      delayed => DateTime->from_epoch(epoch => $options->{delay} ? time + $options->{delay} : 1)
    },
    '$unset' => {map { $_ => '' } qw(finished result started worker)}
  };

  return !!$self->jobs->update($query, $update)->{n};
}

sub stats {
  my $self = shift;

  my $jobs = $self->jobs;
  my $active =
    @{$self->mongodb->run_command([distinct => $jobs->name, key => 'worker', query => {state => 'active'}])
      ->{values}};
  my $all = $self->workers->find->count;
  my $stats = {active_workers => $active, inactive_workers => $all - $active};
  $stats->{"${_}_jobs"} = $jobs->find({state => $_})->count for qw(active failed finished inactive);
  return $stats;
}

sub unregister_worker { shift->workers->remove({_id => shift}) }

sub worker_info { $_[0]->_worker_info($_[0]->workers->find_one({_id => $_[1]})) }

sub _await {
  my $self = shift;

  my $last = $self->{last} //= MongoDB::OID->new;
  my $cursor = $self->notifications->find({_id => {'$gt' => $last}, c => 'created'})->tailable(1);
  return undef unless my $doc = $cursor->next || $cursor->next;
  $self->{last} = $doc->{_id};
  return 1;
}

sub _job_info {
  my $self = shift;

  return undef unless my $job = shift;
  return {
    args     => $job->{args},
    created  => $job->{created} ? $job->{created}->hires_epoch : undef,
    delayed  => $job->{delayed} ? $job->{delayed}->hires_epoch : undef,
    finished => $job->{finished} ? $job->{finished}->hires_epoch : undef,
    id       => $job->{_id},
    priority => $job->{priority},
    result   => $job->{result},
    retried  => $job->{retried} ? $job->{retried}->hires_epoch : undef,
    retries => $job->{retries} // 0,
    started => $job->{started} ? $job->{started}->hires_epoch : undef,
    state   => $job->{state},
    task    => $job->{task},
    worker  => $job->{worker}
  };
}

sub _notifications {
  my $self = shift;

  # We can only await data if there's a document in the collection
  $self->{capped} ? return : $self->{capped}++;
  my $notifications = $self->notifications;
  return if grep { $_ eq $notifications->name } $self->mongodb->collection_names;

  $self->mongodb->run_command([create => $notifications->name, capped => 1, size => 1048576, max => 128]);
  $notifications->insert({});
}

sub _try {
  my ($self, $oid) = @_;

  my $doc = {
    query => Tie::IxHash->new(
      delayed => {'$lt' => DateTime->from_epoch(epoch => time)},
      state   => 'inactive',
      task => {'$in' => [keys %{$self->minion->tasks}]}
    ),
    fields => {args     => 1, task => 1},
    sort   => {priority => -1},
    update => {'$set' => {started => DateTime->from_epoch(epoch => time), state => 'active', worker => $oid}},
    new    => 1
  };

  return $self->jobs->find_and_modify($doc);
}

sub _update {
  my ($self, $fail, $oid, $err) = @_;

  my $update = {finished => DateTime->from_epoch(epoch => time), state => $fail ? 'failed' : 'finished'};
  $update->{result} = $err if $fail;
  my $query = {_id => $oid, state => 'active'};
  return !!$self->jobs->update($query, {'$set' => $update})->{n};
}

sub _worker_info {
  my $self = shift;

  return undef unless my $worker = shift;

  my $cursor = $self->jobs->find({state => 'active', worker => $worker->{_id}});
  return {
    host     => $worker->{host},
    id       => $worker->{_id},
    jobs     => [map { $_->{_id} } $cursor->all],
    pid      => $worker->{pid},
    started  => $worker->{started}->hires_epoch,
    notified => $worker->{notified}->hires_epoch
  };
}

1;

=encoding utf8

=head1 NAME

Minion::Backend::MongoDB - MongoDB backend for Minion

=head1 SYNOPSIS

  use Minion::Backend::MongoDB;

  my $backend = Minion::Backend::MongoDB->new('mongodb://127.0.0.1:27017');

=head1 DESCRIPTION

L<Minion::Backend::MongoDB> is a L<MongoDB> backend for L<Minion>.

=head1 ATTRIBUTES

L<Minion::Backend::MongoDB> inherits all attributes from L<Minion::Backend> and
implements the following new ones.

=head2 mongodb

  my $mongodb = $backend->mongodb;
  $backend  = $backend->mongodb(MongoDB->new);

L<MongoDB::Database> object used to store collections.

=head2 jobs

  my $jobs = $backend->jobs;
  $backend = $backend->jobs(MongoDB::Collection->new);

L<MongoDB::Collection> object for C<jobs> collection, defaults to one based on L</"prefix">.

=head2 notifications

  my $notifications = $backend->notifications;
  $backend          = $backend->notifications(MongoDB::Collection->new);

L<MongoDB::Collection> object for C<notifications> collection, defaults to one based on L</"prefix">.

=head2 prefix

  my $prefix = $backend->prefix;
  $backend   = $backend->prefix('foo');

Prefix for collections, defaults to C<minion>.

=head2 workers

  my $workers = $backend->workers;
  $backend    = $backend->workers(MongoDB::Collection->new);

L<MongoDB::Collection> object for C<workers> collection, defaults to one based on L</"prefix">.

=head1 METHODS

L<Minion::Backend::MongoDB> inherits all methods from L<Minion::Backend> and implements the following new ones.

=head2 dequeue

  my $info = $backend->dequeue($worker_id, 0.5);

Wait for job, dequeue it and transition from C<inactive> to C<active> state or
return C<undef> if queue was empty.

=head2 enqueue

  my $job_id = $backend->enqueue('foo');
  my $job_id = $backend->enqueue(foo => [@args]);
  my $job_id = $backend->enqueue(foo => [@args] => {priority => 1});

Enqueue a new job with C<inactive> state. These options are currently available:

=over 2

=item delay

  delay => 10

Delay job for this many seconds from now.

=item priority

  priority => 5

Job priority, defaults to C<0>.

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

  my $backend = Minion::Backend::MongoDB->new('mongodb://127.0.0.1:27017');

Construct a new L<Minion::Backend::MongoDB> object.

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

Transition from C<failed> or C<finished> state back to C<inactive>.

These options are currently available:

=over 2

=item delay

  delay => 10

Delay job for this many seconds (from now).

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

=head1 LICENSE

Copyright (C) 2015, Andrey Khozov.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Minion>, L<MongoDB>, L<http://mojolicio.us>.

=cut
