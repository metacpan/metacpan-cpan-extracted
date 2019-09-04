package Minion::Backend::MongoDB;
$Minion::Backend::MongoDB::VERSION = '1.02';
# ABSTRACT: MongoDB backend for Minion

use Mojo::Base 'Minion::Backend';

use boolean;
use BSON::ObjectId;
use BSON::Types ':all';
use DateTime;
use DateTime::Set;
use DateTime::Span;
use Mojo::IOLoop;
use Mojo::URL;
use MongoDB;
use Sys::Hostname 'hostname';
use Tie::IxHash;
use Time::HiRes 'time';

has 'dbclient';
has 'mongodb';
has jobs          => sub { $_[0]->mongodb->coll($_[0]->prefix . '.jobs') };
has notifications => sub { $_[0]->mongodb->coll($_[0]->prefix . '.notifications') };
has prefix        => 'minion';
has workers       => sub { $_[0]->mongodb->coll($_[0]->prefix . '.workers') };
has locks         => sub { $_[0]->mongodb->coll($_[0]->prefix . '.locks') };
has admin         => sub { $_[0]->dbclient->db('admin') };

sub broadcast {
  my ($s, $command, $args, $ids) = (shift, shift, shift || [], shift || []);

  my $match = {};
  $match->{_id} = {'$in' => $ids} if (scalar(@$ids));

  my $res = $s->workers->update_many(
    $match, {'$push' => {inbox => [$command, @$args]}}
  );

  return !!$res->matched_count;
}

sub dequeue {
  my ($self, $oid, $wait, $options) = @_;

  if ((my $job = $self->_try($oid, $options))) { return $job }
  return undef if Mojo::IOLoop->is_running;

  # Capped collection for notifications
  $self->_notifications;

  my $timer = Mojo::IOLoop->timer($wait => sub { Mojo::IOLoop->stop });
  my $recur = Mojo::IOLoop->recurring(1 => sub {
      Mojo::IOLoop->stop if ($self->_await)
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($recur);
  Mojo::IOLoop->remove($timer);

  return $self->_try($oid, $options);

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
    delayed  => DateTime->now()->add(seconds => $options->{delay} // 0),
    priority => $options->{priority} // 0,
    state    => 'inactive',
    task     => $task,
    retries  => 0,
    attempts => $options->{attempts} // 1,
    notes    => $options->{notes} || {},
    parents  => $options->{parents} || [],
    queue    => $options->{queue} // 'default',
  };

  my $res = $self->jobs->insert_one($doc);
  my $oid = $res->inserted_id;
  $self->notifications->insert_one({c => 'created'});
  return $oid;
}

sub fail_job { shift->_update(1, @_) }

sub finish_job { shift->_update(0, @_) }

sub history {
  my $self = shift;

  my $dt_stop     = DateTime->now;
  my $dt_start    = $dt_stop->clone->add(days => -1);
  my $dt_span     = DateTime::Span->from_datetimes(
    start => $dt_start,
    end => $dt_stop
  );
  my $dt_set      = DateTime::Set->from_recurrence(
    recurrence => sub { return $_[0]->truncate(to => 'hour')->add(hours => 1) }
  );
  my @dt_set      = $dt_set->as_list(span => $dt_span);
  my %acc = (map {&_dtkey($_) => {
      epoch    => $_->epoch(),
      failed_jobs   => 0,
      finished_jobs => 0
  }} @dt_set);

  my $match  = {'$match' => { finished => {'$gt' => $dt_start} } };
  my $group  = {'$group' => {
    '_id'  => {
        hour    => {'$hour' => {date => '$finished'}},
        day     => {'$dayOfYear' => {date => '$finished'}},
        year    => {'$year' => {date => '$finished'}}
    },
    finished_jobs => {'$sum' => {
        '$cond' => {if => {'$eq' => ['$state', 'finished']}, then => 1, else => 0}
    }},
    failed_jobs => {'$sum' => {
        '$cond' => {if => {'$eq' => ['$state', 'failed']}, then => 1, else => 0}
    }}
  }};

  my $cursor = $self->jobs->aggregate([$match, $group]);

  while (my $doc = $cursor->next) {
    my $dt_finished = DateTime->new(
        year => $doc->{_id}->{year},
        month => 1,
        day => 1,
        hour => $doc->{_id}->{hour},
    );
    $dt_finished->add(days => $doc->{_id}->{day}-1);
    my $key = &_dtkey($dt_finished);
    $acc{$key}->{$_} += $doc->{$_} for(qw(finished_jobs failed_jobs));
  }

  return {daily => [@acc{(sort keys(%acc))}]};
}

sub _dtkey {
    return substr($_[0]->datetime, 0, -6);
}

sub list_jobs {
  my ($self, $lskip, $llimit, $options) = @_;

  my $imatch    = {};
  $options->{'_ids'} = [map(BSON::ObjectId->new($_), @{$options->{ids}})]
    if $options->{ids};
  foreach (qw(_id state task queue)) {
      $imatch->{$_} = {'$in' => $options->{$_ . 's'}} if $options->{$_ . 's'};
  }
  if ($options->{notes}) {
      foreach (@{$options->{notes}}) {
          $imatch->{"notes.$_"} = {'$exists' => 1}
      }
  }

  my $match     = { '$match' => $imatch };
  my $lookup    = {'$lookup' => {
      from          => $self->prefix . '.jobs',
      localField    => '_id',
      foreignField  => 'parents',
      as            => 'children'
  }};
  my $skip      = { '$skip'     => 0 + $lskip },
  my $limit     = { '$limit'    => 0 + $llimit },
  my $sort      = { '$sort'     => { _id => -1 } };
  my $iproject  = {};
  foreach (qw(_id args attempts children notes priority queue result
    retries state task worker)) {
        $iproject->{$_} = 1;
  }
  foreach (qw(parents)) {
        $iproject->{$_} = { '$ifNull' =>  ['$' . $_ , [] ]};
  }
  foreach (qw(created delayed finished retried started)) {
        $iproject->{$_} = {'$toLong' => {'$multiply' => [{
            '$convert' => { 'input' => '$'. $_, to => 'long'}}, 0.001]}};
  }
  $iproject->{total} = { '$size' => '$children'};
  my $project   = { '$project' => $iproject};

  my $aggregate = [$match, $lookup, $sort, $skip, $limit, $project];

  my $cursor    = $self->jobs->aggregate($aggregate);
  my $total     = $self->jobs->count_documents($imatch);

  my $jobs = [map $self->_job_info($_), $cursor->all];
  return _total('jobs', $jobs, $total);
}

sub list_locks {
  my ($self, $offset, $limit, $options) = @_;

  my %aggregate;

  my $imatch    = {};
  $imatch->{expires} = {'$gt' => bson_time()};
  $imatch->{name} = {'$in' => $options->{'names'} } if $options->{'names'};

  $aggregate{match}     = { '$match'    => $imatch };
  $aggregate{unwind}    = { '$unwind'   => '$expires' };
  $aggregate{skip}      = { '$skip'     => $offset // 0 },
  $aggregate{limit}     = { '$limit'    => $limit } if ($limit);

  my $iproject  = {};
  foreach (qw(expires)) {
        $iproject->{$_} = {'$toLong' => {'$multiply' => [{
            '$convert' => { 'input' => '$'. $_, to => 'long'}}, 0.001]}};
  }
  $iproject->{_id} = 0;
  $iproject->{name} = 1;

  $aggregate{project}   = { '$project' => $iproject};
  $aggregate{sort}      = { '$sort'     => { expires => -1 } };


  my @aggregate = grep defined, map {$aggregate{$_}}
   qw(match unwind sort skip limit project);

  my $cursor    = $self->locks->aggregate(\@aggregate);
  my $total     = $self->_locks_count($imatch);

  my $locks = [$cursor->all];

  return _total('locks', $locks, $total);
}

sub list_workers {
  my ($self, $offset, $limit, $options) = @_;

  my $cursor = $self->workers->find({pid => {'$exists' => true}});
  my $total = scalar($cursor->all);
  $cursor->reset;
  $cursor->sort({_id => -1})->skip($offset)->limit($limit);
  my $workers =  [map { $self->_worker_info($_) } $cursor->all];
  return _total('workers', $workers, $total);
}

sub lock {
  my ($s, $name, $duration, $options) = (shift, shift, shift, shift // {});
  return $s->_lock($name, $duration, $options->{limit} || 1);
}

sub new {
  my ($class, $url) = (shift, shift);
  my $client = MongoDB::MongoClient->new(host => $url, @_);
  my $db = $client->db($client->db_name);

  my $self = $class->SUPER::new(dbclient => $client, mongodb => $db);
  Mojo::IOLoop->singleton->on(reset => sub {
      $self->mongodb->client->reconnect();
  });

  return $self;
}

sub note {
  my ($self, $id, $merge) = @_;

  return 1 unless defined $merge;
  my $set = {};
  my $unset = {};
  while (my ($k, $v) = each %$merge) {
      (defined $v ? $set : $unset)->{"notes.$k"} = $v;
  };
  my @update = ( {_id => $id} );
  push @update, {'$set' => $set} if (keys %$set);
  push @update, {'$unset' => $unset} if (keys %$unset);
  push @update, {
      upsert    => 0,
      returnDocument => 'after',
  };
  return $self->jobs->find_one_and_update(@update) ? 1 : 0;
}

sub receive {
  my ($self, $id) = @_;
  my $oldrec = $self->workers->find_one_and_update(
    {_id => $id, inbox => { '$exists' => 1, '$ne' => [] } },
    {'$set' => {inbox => [] }},
    {
        upsert    => 0,
        returnDocument => 'before',
    }
  );

  return $oldrec ? $oldrec->{inbox} // [] : [];
}

sub register_worker {
  my ($self, $id, $options) = @_;

  return $id
    if $id
    && $self->workers->find_one_and_update(
    {_id => $id}, {'$set' => {
        notified => DateTime->from_epoch(epoch => time),
        status => $options->{status} // {}
    }});

  $self->jobs->indexes->create_one(Tie::IxHash->new(state => 1, delayed => 1, task => 1, queue => 1));
  $self->jobs->indexes->create_one(Tie::IxHash->new(finished => 1));
  $self->locks->indexes->create_one(Tie::IxHash->new(name => 1), {unique => 1});
  $self->locks->indexes->create_one(Tie::IxHash->new(expires => 1));
  my $res = $self->workers->insert_one(
    { host     => hostname,
      pid      => $$,
      started  => DateTime->from_epoch(epoch => time),
      notified => DateTime->from_epoch(epoch => time),
      status => $options->{status} // {},
      inbox => [],
    }
  );

  return $res->inserted_id;
}

sub remove_job {
  my ($self, $oid) = @_;
  my $doc = {_id => $oid, state => {'$in' => [qw(failed finished inactive)]}};
  return !!$self->jobs->delete_one($doc)->deleted_count;
}

sub repair {
  my $self   = shift;
  my $minion = $self->minion;

  # Check worker registry
  my $workers = $self->workers;

  $workers->delete_many({notified => {
      '$lt' => DateTime->from_epoch(epoch => time - $minion->missing_after)}});

  # Abandoned jobs
  my $jobs = $self->jobs;
  my $cursor = $jobs->find({
      state => 'active',
      queue => {'$ne' => 'minion_foreground'}
  });
  while (my $job = $cursor->next) {
    $self->fail_job(@$job{qw(_id retries)}, 'Worker went away')
        unless $workers->count_documents({_id => $job->{worker}});
  }

  # Old jobs with no unresolved dependencies
  $cursor = $jobs->find(
    {state => 'finished', finished => {
        '$lt' => DateTime->from_epoch(epoch => time - $minion->remove_after)}}
  );

  while (my $job = $cursor->next) {
    $jobs->delete_one({_id => $job->{_id}})
        unless ($self->jobs->count_documents({
            parents => $job->{_id},
            state => {'$ne' => 'finished'}
        }));
  }
}

sub reset { $_->drop for $_[0]->workers, $_[0]->jobs, $_[0]->locks }

sub retry_job {
  my ($self, $oid, $retries, $options) = (shift, shift, shift, shift || {});
  $options->{delay} //= 0;

  my $dt_now = DateTime->now();

  my $query = {_id => $oid, retries => $retries};
  my $update = {
    '$inc' => {retries => 1},
    '$set' => {
      retried => $dt_now,
      state   => 'inactive',
      delayed => $dt_now->clone->add(seconds => $options->{delay})
    },
  };

  foreach(qw(attempts parents priority queue)) {
      $update->{'$set'}->{$_} = $options->{$_} if (defined $options->{$_});
  }

  my $res = $self->jobs->update_one($query, $update);
  $self->notifications->insert_one({c => 'update_retries'});
  return !!$res->matched_count;
}

sub stats {
  my $self = shift;

  my $jobs = $self->jobs;
  my $active =
    @{$self->mongodb->run_command([distinct => $jobs->name, key => 'worker', query => {state => 'active'}])
      ->{values}};
  my $all = $self->workers->count_documents({});
  my $stats = {active_workers => $active, inactive_workers => $all - $active};
  $stats->{"${_}_jobs"} = $jobs->count_documents({state => $_}) for qw(active failed finished inactive);
  $stats->{active_locks} = $self->list_locks->{total};
  $stats->{delayed_jobs} = $self->jobs->count_documents({
      state => 'inactive',
      delayed => {'$gt' => bson_time}
  });
  # I don't know if this value is correct as calculated. PG use the incremental
  # sequence id
  $stats->{enqueued_jobs} += $stats->{"${_}_jobs"} for qw(active failed finished inactive);
  eval {
      $stats->{uptime} = $self->admin->run_command(Tie::IxHash->new('serverStatus' => 1))->{uptime};
  };
  # User doesn't have admin authorization. Server uptime missing
  $stats->{uptime} = -1 if ($@);
  return $stats;
}

sub unlock {
    my ($s, $name) = @_;

    # remove the first (more proximum to expiration) lock
    my $doc = $s->locks->find_one_and_update(
        {name => $name},
        {'$pop' => {expires => -1}}
    );

    # delete lock record if expires is empty
    $s->locks->delete_one({name => $name, expires => {'$size' => 0}}) if ($doc);

    return defined $doc ;
}
sub unregister_worker { shift->workers->delete_one({_id => shift}) }

sub worker_info { $_[0]->_worker_info($_[0]->workers->find_one({_id => $_[1]})) }

sub _await {
  my $self = shift;

  my $last = $self->{last} //= BSON::OID->new;
  my $cursor = $self->notifications->find({
    _id => {'$gt' => $last},
    '$or' =>  [
        { c => 'created'},
        { c => 'update_retries'}
    ]
  })->tailable(1);
  return undef unless my $doc = $cursor->next || $cursor->next;
  $self->{last} = $doc->{_id};
  return 1;
}

sub _job_info {
  my $self = shift;

  return undef unless my $job = shift;

  $job->{id}        = $job->{_id};
  $job->{retries} //= 0;
  $job->{children}  = [map $_->{_id}->hex, @{$job->{children}}];
  $job->{time}      = DateTime->now->epoch; # server time

  return $job;
}

sub _lock {
    my ($s, $name, $duration, $count) = @_;

    my $dt_now = DateTime->now;
    my $dt_exp = $dt_now->clone->add(seconds => $duration);


    my $match = {name => $name};

    # expires count (I know, this is not atomic, I didn't find any alternative)
    return 0 if $s->_locks_count($match) >= $count;

    # ok, can add lock sorting by first to last expiration
    my $ret = $s->locks->find_one_and_update(
        $match,
        {
            '$push' => {
                expires => {
                    '$each' => [$dt_exp],
                    '$sort' => 1
                }
            }
        },
        { upsert => 1 }
    );

    # remove expired locks
    my $del = $s->locks->update_many({}, {'$pull' => {expires => {'$lte' => $dt_now}}});
    # delete lock record if expires is empty
    $s->locks->delete_one({name => $name, expires => {'$size' => 0}})
        if ($del->{modified_count});

    return 1;
}

sub _locks_count {
    my $s = shift;
    my $match = shift;

    my @aggregate = (
        { '$group' => {
            _id         => undef,
            locks_count => { '$sum' =>  { '$size' => '$expires' } }
        } },
        { '$project' => { _id => 0 } }
    );

    unshift @aggregate, {'$match' => $match} if $match;

    my $rec = $s->locks->aggregate(\@aggregate)->next;

    return $rec ? $rec->{locks_count} : 0;
}

sub _notifications {
  my $self = shift;

  # We can only await data if there's a document in the collection
  $self->{capped} ? return : $self->{capped}++;
  my $notifications = $self->notifications;
  return if grep { $_ eq $notifications->name } $self->mongodb->collection_names;

  $self->mongodb->run_command([create => $notifications->name, capped => 1, size => 1048576, max => 128]);
  $notifications->insert_one({});
}

sub _total {
    my ($name, $res, $tot) = @_;
    return { total => $tot, $name => $res};
}

sub _try {
  my ($self, $oid, $options) = @_;

  my $match = Tie::IxHash->new(
    delayed   => {'$lt' => DateTime->from_epoch(epoch => time)},
    state     => 'inactive',
    task      => {'$in' => [keys %{$self->minion->tasks}]},
    queue     => {'$in' => $options->{queues} // ['default']}
  );
  $match->Push('_id' => $options->{id}) if defined $options->{id};

  my $docs = $self->jobs->find($match)->sort({priority => -1, id => 1});

  my $find = 0;
  my $doc_matched;
  while ((my $doc = $docs->next) && !$find) {
    # parents not exits or
    # exists but are not in inactive, active, failed states
    $find = !scalar @{$doc->{parents}} ||
        !$self->jobs->count_documents({
            _id => {'$in' => $doc->{parents}},
            state => {'$in' => ['inactive', 'active', 'failed']}
    });
    $doc_matched = $doc if $find;
  }

  return undef unless $doc_matched;

  my $doc = [
    {_id => $doc_matched->{_id}, state => 'inactive'},
    {'$set' => {
        started => DateTime->from_epoch(epoch => time),
        state => 'active',
        worker => $oid
    }},
    {
        projection      => {args => 1, retries => 1, task => 1},
        upsert          => 0,
        returnDocument  => 'after',
    }
  ];

  my $job = $self->jobs->find_one_and_update(@$doc);
  return undef unless ($job->{_id});
  $job->{id} = $job->{_id};
  return $job;
}

sub _update {
  my ($self, $fail, $oid, $retries, $result) = @_;

  my $update = {
      finished => DateTime->now,
      state => $fail ? 'failed' : 'finished',
      result => $fail ?  $result . '' : $result ,
  };
  my $query = {_id => $oid, state => 'active', retries => $retries};
  my $doc = $self->jobs->find_one_and_update($query, {'$set' => $update},
    {returnDocument => 'after'});

  return undef unless ($doc->{attempts});

  return 1 if !$fail || (my $attempts = $doc->{attempts}) == 1;
  return 1 if $retries >= ($attempts - 1);
  my $delay = $self->minion->backoff->($retries);
  return $self->retry_job($oid, $retries, {delay => $delay});
}

sub _worker_info {
  my $self = shift;

  return undef unless my $worker = shift;

  # lookup jobs
  my $cursor = $self->jobs->find({state => 'active', worker => $worker->{_id}});

  return {
    host     => $worker->{host},
    id       => $worker->{_id},
    jobs     => [map { $_->{_id} } $cursor->all],
    pid      => $worker->{pid},
    started  => $worker->{started}->epoch,
    notified => $worker->{notified}->epoch,
    inbox    => $worker->{inbox},
    status   => $worker->{status},
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Minion::Backend::MongoDB - MongoDB backend for Minion

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  use Minion::Backend::MongoDB;

  my $backend = Minion::Backend::MongoDB->new('mongodb://127.0.0.1:27017');

=head1 DESCRIPTION

L<Minion::Backend::MongoDB> is a L<MongoDB> backend for L<Minion>
derived from L<Minion::Backend::Pg> and supports its methods and tests
up to 9.11.

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

=head2 broadcast

  my $bool = $backend->broadcast('some_command');
  my $bool = $backend->broadcast('some_command', [@args]);
  my $bool = $backend->broadcast('some_command', [@args], [$id1, $id2, $id3]);

Broadcast remote control command to one or more workers.

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

=item ids

  ids => ['23', '24']

List only jobs with these ids.

=item notes

  notes => ['foo', 'bar']

List only jobs with one of these notes. Note that this option is EXPERIMENTAL
and might change without warning!

=item queues

  queues => ['important', 'unimportant']

List only jobs in these queues.

=item state

  state => 'inactive'

List only jobs in this state.

=item task

  task => 'test'

List only jobs for this task.

=back

These fields are currently available:

=over 2

=item args

  args => ['foo', 'bar']

Job arguments.

=item attempts

  attempts => 25

Number of times performing this job will be attempted.

=item children

  children => ['10026', '10027', '10028']

Jobs depending on this job.

=item created

  created => 784111777

Epoch time job was created.

=item delayed

  delayed => 784111777

Epoch time job was delayed to.

=item finished

  finished => 784111777

Epoch time job was finished.

=item id

  id => 10025

Job id.

=item notes

  notes => {foo => 'bar', baz => [1, 2, 3]}

Hash reference with arbitrary metadata for this job.

=item parents

  parents => ['10023', '10024', '10025']

Jobs this job depends on.

=item priority

  priority => 3

Job priority.

=item queue

  queue => 'important'

Queue name.

=item result

  result => 'All went well!'

Job result.

=item retried

  retried => 784111777

Epoch time job has been retried.

=item retries

  retries => 3

Number of times job has been retried.

=item started

  started => 784111777

Epoch time job was started.

=item state

  state => 'inactive'

Current job state, usually C<active>, C<failed>, C<finished> or C<inactive>.

=item task

  task => 'foo'

Task name.

=item time

  time => 78411177

Server time.

=item worker

  worker => '154'

Id of worker that is processing the job.

=back

=head2 list_locks

  my $results = $backend->list_locks($offset, $limit);
  my $results = $backend->list_locks($offset, $limit, {names => ['foo']});

Returns information about locks in batches.

  # Get the total number of results (without limit)
  my $num = $backend->list_locks(0, 100, {names => ['bar']})->{total};

  # Check expiration time
  my $results = $backend->list_locks(0, 1, {names => ['foo']});
  my $expires = $results->{locks}[0]{expires};

These options are currently available:

=over 2

=item names

  names => ['foo', 'bar']

List only locks with these names.

=back

These fields are currently available:

=over 2

=item expires

  expires => 784111777

Epoch time this lock will expire.

=item name

  name => 'foo'

Lock name.

=back

=head2 list_workers

  my $results = $backend->list_workers($offset, $limit);
  my $results = $backend->list_workers($offset, $limit, {ids => [23]});

Returns information about workers in batches.

  # Get the total number of results (without limit)
  my $num = $backend->list_workers(0, 100)->{total};

  # Check worker host
  my $results = $backend->list_workers(0, 1, {ids => [$worker_id]});
  my $host    = $results->{workers}[0]{host};

These options are currently available:

=over 2

=item ids

  ids => ['23', '24']

List only workers with these ids.

=back

These fields are currently available:

=over 2

=item id

  id => 22

Worker id.

=item host

  host => 'localhost'

Worker host.

=item jobs

  jobs => ['10023', '10024', '10025', '10029']

Ids of jobs the worker is currently processing.

=item notified

  notified => 784111777

Epoch time worker sent the last heartbeat.

=item pid

  pid => 12345

Process id of worker.

=item started

  started => 784111777

Epoch time worker was started.

=item status

  status => {queues => ['default', 'important']}

Hash reference with whatever status information the worker would like to share.

=back

=head2 lock

  my $bool = $backend->lock('foo', 3600);
  my $bool = $backend->lock('foo', 3600, {limit => 20});

Try to acquire a named lock that will expire automatically after the given
amount of time in seconds. An expiration time of C<0> can be used to check if a
named lock already exists without creating one.

These options are currently available:

=over 2

=item limit

  limit => 20

Number of shared locks with the same name that can be active at the same time,
defaults to C<1>.

=back

=head2 new

  my $backend = Minion::Backend::MongoDB->new('mongodb://127.0.0.1:27017');

Construct a new L<Minion::Backend::MongoDB> object. Required a
L<connection string URI|MongoDB::MongoClient/"CONNECTION STRING URI">. Optional
every other attributes will be pass to L<MongoDB::MongoClient> costructor.

=head2 note

  my $bool = $backend->note($job_id, {mojo => 'rocks', minion => 'too'});

Change one or more metadata fields for a job. Setting a value to C<undef> will
remove the field.

=head2 receive

  my $commands = $backend->receive($worker_id);

Receive remote control commands for worker.

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

=head1 NOTES ABOUT USER

User must have this roles

  "roles" : [
                {
                        "role" : "dbAdmin",
                        "db" : "minion"
                },
                {
                        "role" : "clusterMonitor",
                        "db" : "admin"
                },
                {
                        "role" : "readWrite",
                        "db" : "minion"
                }
        ]

=head1 SEE ALSO

L<Minion>, L<MongoDB>, L<http://mojolicio.us>.

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>, Andrey Khozov <avkhozov@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Emiliano Bruni, Andrey Khozov.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
