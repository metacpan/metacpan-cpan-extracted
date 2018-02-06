package Minion::Backend::mysql;

use 5.010;

use Mojo::Base 'Minion::Backend';

use Mojo::IOLoop;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::mysql;
use Sys::Hostname 'hostname';

has 'mysql';

our $VERSION = '0.13';

sub dequeue {
  my ($self, $id, $wait, $options) = @_;

  if ((my $job = $self->_try($id, $options))) { return $job }
  return undef if Mojo::IOLoop->is_running;

  my $cb = $self->mysql->pubsub->listen("minion.job" => sub {
    Mojo::IOLoop->stop;
  });

  my $timer = Mojo::IOLoop->timer($wait => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;

  $self->mysql->pubsub->unlisten("minion.job" => $cb) and Mojo::IOLoop->remove($timer);

  return $self->_try($id, $options);
}

sub enqueue {
  my ($self, $task) = (shift, shift);
  my $args    = shift // [];
  my $options = shift // {};

  my $db = $self->mysql->db;

  my $seconds = $db->dbh->quote($options->{delay} // 0);
  $db->query(
    "insert into minion_jobs (`args`, `attempts`, `delayed`, `priority`, `queue`, `task`, `notes`)
     values (?, ?, (DATE_ADD(NOW(), INTERVAL $seconds SECOND)), ?, ?, ?, ?)",
     encode_json($args), $options->{attempts} // 1,
     $options->{priority} // 0, $options->{queue} // 'default', $task,
     encode_json( $options->{notes} // {} ),
  );
  my $job_id = $db->dbh->{mysql_insertid};

  if ( my @parents = @{ $options->{parents} || [] } ) {
    $db->query(
      "INSERT IGNORE INTO minion_jobs_depends (`parent_id`, `child_id`) VALUES "
      . join( ", ", map "( ?, ? )", @parents ),
      map { $_, $job_id  } @parents
    );
  }

  $self->mysql->pubsub->notify("minion.job" => $job_id);

  return $job_id;
}

sub note {
  my ($self, $id, $key, $value) = @_;
  my $job = $self->mysql->db->query(
    'SELECT notes FROM minion_jobs WHERE id=?', $id,
  )->hash || return 0;
  my $notes = decode_json( $job->{notes} );
  $notes->{ $key } = $value;
  return !!$self->mysql->db->query(
    'UPDATE minion_jobs SET notes = ? WHERE id = ?',
    encode_json( $notes ), $id,
  )->rows;
}

sub fail_job   { shift->_update(1, @_) }
sub finish_job { shift->_update(0, @_) }

sub list_jobs {
  my ($self, $offset, $limit, $options) = @_;

  my ( @where, @params );
  if ( my $state = $options->{state} ) {
    my @states = ref $state eq 'ARRAY' ? @$state : ( $state );
    push @where, 'state in (' . join( ',', ('?') x @states ) . ')';
    push @params, @states;
  }
  if ( my $queue = $options->{queue} ) {
    my @queues = ref $queue eq 'ARRAY' ? @$queue : ( $queue );
    push @where, 'queue in (' . join( ',', ('?') x @queues ) . ')';
    push @params, @queues;
  }
  if ( my $task = $options->{task} ) {
    my @tasks = ref $task eq 'ARRAY' ? @$task : ( $task );
    push @where, 'task in (' . join( ',', ('?') x @tasks ) . ')';
    push @params, @tasks;
  }
  if ( my $id = $options->{ids} ) {
    my @ids = ref $id eq 'ARRAY' ? @$id : ( $id );
    push @where, 'id in (' . join( ',', ('?') x @ids ) . ')';
    push @params, @ids;
  }

  my $where = @where ? 'WHERE ' . join( ' AND ', @where ) : '';
  my $jobs = $self->mysql->db->query(
    "SELECT
      id, args, attempts,
      UNIX_TIMESTAMP(created) AS created,
      UNIX_TIMESTAMP(`delayed`) AS `delayed`,
      UNIX_TIMESTAMP(finished) AS finished, priority,
      queue, result, UNIX_TIMESTAMP(retried) AS retried, retries,
      UNIX_TIMESTAMP(started) AS started, state, task,
      GROUP_CONCAT( child_jobs.child_id SEPARATOR ':' ) AS children,
      GROUP_CONCAT( parent_jobs.parent_id SEPARATOR ':' ) AS parents,
      worker, notes
    FROM minion_jobs
    LEFT JOIN minion_jobs_depends child_jobs ON minion_jobs.id=child_jobs.parent_id
    LEFT JOIN minion_jobs_depends parent_jobs ON minion_jobs.id=parent_jobs.child_id
    $where
    GROUP BY minion_jobs.id, child_jobs.parent_id, parent_jobs.child_id
    ORDER BY id DESC
    LIMIT ?
    OFFSET ?", @params, $limit, $offset,
  )->hashes;
  $jobs->map( _decode_json_fields(qw{ args result notes }) )
    ->each( sub {
      $_->{children} = [ split /:/, $_->{children} // '' ];
      $_->{parents} = [ split /:/, $_->{parents} // '' ];
    } );

  #; use Data::Dumper;
  #; say Dumper $jobs;

  my $total = $self->mysql->db->query(
    'SELECT COUNT(*) AS count FROM minion_jobs',
  )->hash->{count};

  return {
    jobs => $jobs,
    total => $total,
  }
}

sub _decode_json_fields {
  my @fields = @_;
  return sub {
    my $hash = shift;
    for my $field ( @fields ) {
      next unless $hash->{ $field };
      $hash->{ $field } = decode_json( $hash->{ $field } );
    }
    return $hash;
  };
}

sub list_workers {
  my ($self, $offset, $limit, $options) = @_;

  my ( @where, @params );
  if ( my $ids = $options->{ids} ) {
    push @where, 'id in (' . join( ',', ('?') x @{$options->{ids}} ) . ')';
    push @params, @{ $options->{ids} };
  }

  my $where = @where ? 'WHERE ' . join ' AND ', @where : '';
  my $sql = "SELECT
    id, UNIX_TIMESTAMP(notified) AS notified, host, pid,
    UNIX_TIMESTAMP(started) AS started, status
  FROM minion_workers $where ORDER BY id DESC LIMIT ? OFFSET ?";
  my $workers = $self->mysql->db->query($sql, @params, $limit, $offset)
    ->hashes;

  # Add jobs to each worker
  my $jobs_sql = q{SELECT id FROM minion_jobs WHERE state='active' AND worker=?};
  $workers->map( sub {
      $_->{status} = decode_json( $_->{status} );
      $_->{jobs} = $self->mysql->db->query($jobs_sql, $_->{id})->arrays->flatten->to_array
  } );

  my $total = $self->mysql->db->query(
    'SELECT COUNT(*) AS count FROM minion_workers',
  )->hash->{count};

  return {
    workers => $workers,
    total => $total,
  };
}

sub list_locks {
  my ($self, $offset, $limit, $options) = @_;

  my ( @where, @params );
  if ( $options->{name} ) {
    push @where, 'name = ?';
    push @params, $options->{name};
  }

  push @where, 'expires > now()';

  my $where = @where ? 'WHERE ' . join ' AND ', @where : '';
  my $sql = "SELECT
          id, name, UNIX_TIMESTAMP(expires) AS expires
      FROM minion_locks
      $where
      ORDER BY id
      DESC LIMIT ? OFFSET ?";

  my $locks = $self->mysql->db->query($sql, @params, $limit || 0, $offset || 0)->hashes;

  my $total = $self->mysql->db->query(
    "SELECT COUNT(name) AS total FROM minion_locks $where", @params
  )->hash->{total};

  return {
    locks => $locks,
    total => $total,
  };
}

sub new {
  my ( $class, @args ) = @_;
  if ( ref $args[0] eq 'HASH' ) {
    @args = %{ $args[0] };
  }
  my $self = $class->SUPER::new(mysql => Mojo::mysql->new(@args));
  my $mysql = $self->mysql->max_connections(1);
  $mysql->migrations->name('minion')->from_data;
  $mysql->once(connection => sub { shift->migrations->migrate });
  return $self;
}

sub register_worker {
  my ($self, $id, $options) = @_;

  my $db = $self->mysql->db;
  my $sql = q{INSERT INTO minion_workers (id, host, pid, status)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE notified=NOW(), host=VALUES(host), pid=VALUES(pid), status=VALUES(status)};
  $db->query($sql, $id, hostname, $$, encode_json( $options->{status} // {} ) );

  return $id // $db->dbh->{mysql_insertid};
}

sub remove_job {
  !!shift->mysql->db->query(
    "delete from minion_jobs
     where id = ? and state in ('inactive', 'failed', 'finished')",
     shift
  )->{affected_rows};
}

sub repair {
  my $self = shift;

  # Check worker registry
  my $db     = $self->mysql->db;
  my $minion = $self->minion;
  $db->query(
    "delete from minion_workers
     where notified < (DATE_SUB(NOW(), INTERVAL ? SECOND))",
     $minion->missing_after
  );

  # Abandoned jobs
  my $fail = $db->query(
    "select id, retries from minion_jobs as j
     where state = 'active'
       and not exists (select 1 from minion_workers where id = j.worker)"
  )->hashes;
  $fail->each(sub { $self->fail_job(@$_{qw(id retries)}, 'Worker went away') });

  # Old jobs with no unresolved dependencies
  $db->query( q{
    DELETE FROM minion_jobs
    WHERE state = 'finished'
      AND finished <= (DATE_SUB(NOW(), INTERVAL ? SECOND))
      AND state='finished'
      AND NOT EXISTS (
        SELECT 1 FROM ( SELECT id, state FROM minion_jobs ) AS child
        LEFT JOIN minion_jobs_depends depends ON child.id=depends.child_id
        WHERE parent_id=minion_jobs.id AND child.state != 'finished'
      )
    }, $minion->remove_after,
  );

}

sub reset {
    my $self = shift;

    $self->mysql->db->query("delete from minion_jobs");
    $self->mysql->db->query("truncate table minion_locks");
    $self->mysql->db->query("truncate table minion_workers");
}

sub lock {
  my ($self, $name, $duration, $options) = (shift, shift, shift, shift // {});
  return !!$self->mysql->db->query('SELECT minion_lock(?, ?, ?)',
    $name, $duration, $options->{limit} || 1)->array->[0];
}

sub unlock {
  !!shift->mysql->db->query(
    'DELETE FROM minion_locks WHERE id IN (
       SELECT b.id FROM (SELECT id, expires, name FROM minion_locks) b
       WHERE b.expires > NOW() AND b.name = ? ORDER BY EXPIRES
     ) LIMIT 1', shift
  )->rows;
}

sub retry_job {
  my ($self, $id, $retries) = (shift, shift, shift);
  my $options = shift // {};

  my $seconds = $self->mysql->db->dbh->quote($options->{delay} // 0);

  return !!$self->mysql->db->query(
    "UPDATE `minion_jobs`
     SET attempts = COALESCE(?, attempts),
       `delayed` = DATE_ADD(NOW(), INTERVAL $seconds SECOND),
       priority = COALESCE(?, priority), queue = COALESCE(?, queue),
       retried = NOW(), retries = retries + 1, state = 'inactive'
     WHERE id = ? AND retries = ?",
     $options->{attempts},
     @$options{qw(priority queue)}, $id, $retries
  )->{affected_rows};
}

sub stats {
  my $self = shift;

  my $db  = $self->mysql->db;
  my $all = $db->query('select count(*) from minion_workers')->array->[0];
  my $sql
    = "select count(distinct worker) from minion_jobs where state = 'active'";
  my $active = $db->query($sql)->array->[0];

  #### TODO: odd $a and $b weren't working, or something
  $sql = 'select state, count(state) from minion_jobs group by 1';
  my $results
    = $db->query($sql); # ->reduce(sub { $a->{$b->[0]} = $b->[1]; $a }, {});

  my $states = {};
  while (my $next = $results->array) {
    $states->{$next->[0]} = $next->[1];
  }

  my $uptime = $db->query( 'SHOW GLOBAL STATUS LIKE "Uptime"' )->hash->{Value};

  $sql = q{
    SELECT
      SUM(CASE WHEN `state` = "inactive" AND `delayed` > NOW() THEN 1 ELSE 0 END) AS delayed_jobs,
      COUNT(*) AS enqueued_jobs
      FROM minion_jobs
    };
  %$states = ( %$states, %{ $db->query($sql)->hash } );
  $states->{active_locks} = $db->query("SELECT COUNT(*) FROM minion_locks WHERE expires > now()")->array->[0];

  return {
    active_workers   => $active,
    inactive_workers => $all - $active,
    active_jobs      => $states->{active} || 0,
    inactive_jobs    => $states->{inactive} || 0,
    failed_jobs      => $states->{failed} || 0,
    finished_jobs    => $states->{finished} || 0,
    enqueued_jobs    => $states->{enqueued_jobs} || 0,
    delayed_jobs     => $states->{delayed_jobs} || 0,
    active_locks     => $states->{active_locks} || 0,
    uptime           => $uptime || 0,
  };
}

sub unregister_worker {
  shift->mysql->db->query('delete from minion_workers where id = ?', shift);
}

sub _try {
  my ($self, $id, $options) = @_;

  my $tasks = [keys %{$self->minion->tasks}];

  return  unless @$tasks;

  my $qq = join(", ", map({ "?" } @{ $options->{queues} // ['default'] }));
  my $qt = join(", ", map({ "?" } @{ $tasks }));

  my $db = $self->mysql->db;

  my $tx = $db->begin;
  my $job = $tx->db->query(qq{
    SELECT job.id, job.args, job.retries, job.task
    FROM minion_jobs job
    WHERE job.state = 'inactive' AND job.`delayed` <= NOW()
      AND NOT EXISTS (
        SELECT 1 FROM minion_jobs_depends depends
        LEFT JOIN minion_jobs parent ON parent.id=depends.parent_id
        WHERE child_id=job.id AND parent.id=depends.parent_id AND parent.state IN ( 'inactive', 'active', 'failed' )
      )
      AND job.queue IN ($qq) AND job.task IN ($qt)
    GROUP BY job.id
    ORDER BY job.priority DESC, job.created
    LIMIT 1 FOR UPDATE},
   @{ $options->{queues} || ['default']}, @{ $tasks }
  )->hash;

  #; use Data::Dumper;
  #; say "Dequeuing job: " . Dumper $job;

  return undef unless $job;

  $tx->db->query(
     qq(update minion_jobs set started = now(), state = 'active', worker = ? where id = ?),
     $id, $job->{id}
  );
  $tx->commit;

  $job->{args} = $job->{args} ? decode_json($job->{args}) : undef;

  return $job;
}

sub _update {
  my ($self, $fail, $id, $retries, $result) = @_;
  my $updated = $self->mysql->db->query(
    "update minion_jobs
     set finished = now(), result = ?, state = ?
     where id = ? and retries = ? and state = 'active'",
     encode_json($result), $fail ? 'failed' : 'finished', $id,
    $retries
  )->{affected_rows};
  #; say "Updated $updated job rows (id: $id, fail: $fail, result: @{[encode_json( $result )]})";
  return undef unless $updated;

  my $job = $self->list_jobs( 0, 1, { ids => [$id] } )->{jobs}[0];
  return 1 if !$fail || (my $attempts = $job->{attempts}) == 1;
  return 1 if $retries >= ( $attempts - 1 );
  my $delay = $self->minion->backoff->( $retries );
  return $self->retry_job( $id, $retries, { delay => $delay } );
}

sub broadcast {
  my ($self, $command, $args, $ids) = (shift, shift, shift || [], shift || []);
  my $message = encode_json( [ $command, @$args ] );
  if ( !@$ids ) {
    @$ids = map { $_->{id} }
      @{ $self->mysql->db->query( 'SELECT id FROM minion_workers' )->hashes },
  }
  my $rows = 0;
  for my $id ( @$ids ) {
    $rows += $self->mysql->db->query(
      'INSERT INTO minion_workers_inbox ( worker_id, message ) VALUES ( ?, ? )',
      $id, $message,
    )->rows;
  }
  return $rows;
}

sub receive {
  my ($self, $worker_id) = @_;
  #; use Data::Dumper;
  my $rows = $self->mysql->db->query(
    'SELECT id, message FROM minion_workers_inbox WHERE worker_id=?', $worker_id,
  )->hashes;
  return [] unless $rows && @$rows;
  #; say Dumper $rows;
  my @ids = map { $_->{id} } @$rows;
  #; say Dumper \@ids;
  $self->mysql->db->query(
    'DELETE FROM minion_workers_inbox WHERE id IN (' . ( join ", ", ( '?' ) x @ids ) . ')',
    @ids,
  );
  return [ map { decode_json( $_->{message} ) } @$rows ];
}

1;

#pod =encoding utf8
#pod
#pod =head1 NAME
#pod
#pod Minion::Backend::mysql - MySQL backend
#pod
#pod =head1 SYNOPSIS
#pod
#pod   use Mojolicious::Lite;
#pod
#pod   plugin Minion => {mysql => 'mysql://user@127.0.0.1/minion_jobs'};
#pod
#pod   # Slow task
#pod   app->minion->add_task(poke_mojo => sub {
#pod     my $job = shift;
#pod     $job->app->ua->get('mojolicio.us');
#pod     $job->app->log->debug('We have poked mojolicio.us for a visitor');
#pod   });
#pod
#pod   # Perform job in a background worker process
#pod   get '/' => sub {
#pod     my $c = shift;
#pod     $c->minion->enqueue('poke_mojo');
#pod     $c->render(text => 'We will poke mojolicio.us for you soon.');
#pod   };
#pod
#pod   app->start;
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Minion::Backend::mysql> is a backend for L<Minion> based on L<Mojo::mysql>. All
#pod necessary tables will be created automatically with a set of migrations named
#pod C<minion>. This backend requires at least v5.6.5 of MySQL.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod L<Minion::Backend::mysql> inherits all attributes from L<Minion::Backend> and
#pod implements the following new ones.
#pod
#pod =head2 mysql
#pod
#pod   my $mysql   = $backend->mysql;
#pod   $backend = $backend->mysql(Mojo::mysql->new);
#pod
#pod L<Mojo::mysql> object used to store all data.
#pod
#pod =head1 METHODS
#pod
#pod L<Minion::Backend::mysql> inherits all methods from L<Minion::Backend> and
#pod implements the following new ones.
#pod
#pod =head2 dequeue
#pod
#pod   my $job_info = $backend->dequeue($worker_id, 0.5);
#pod   my $job_info = $backend->dequeue($worker_id, 0.5, {queues => ['important']});
#pod
#pod Wait for job, dequeue it and transition from C<inactive> to C<active> state or
#pod return C<undef> if queues were empty.
#pod
#pod These options are currently available:
#pod
#pod =over 2
#pod
#pod =item queues
#pod
#pod   queues => ['important']
#pod
#pod One or more queues to dequeue jobs from, defaults to C<default>.
#pod
#pod =back
#pod
#pod These fields are currently available:
#pod
#pod =over 2
#pod
#pod =item args
#pod
#pod   args => ['foo', 'bar']
#pod
#pod Job arguments.
#pod
#pod =item id
#pod
#pod   id => '10023'
#pod
#pod Job ID.
#pod
#pod =item retries
#pod
#pod   retries => 3
#pod
#pod Number of times job has been retried.
#pod
#pod =item task
#pod
#pod   task => 'foo'
#pod
#pod Task name.
#pod
#pod =back
#pod
#pod =head2 enqueue
#pod
#pod   my $job_id = $backend->enqueue('foo');
#pod   my $job_id = $backend->enqueue(foo => [@args]);
#pod   my $job_id = $backend->enqueue(foo => [@args] => {priority => 1});
#pod
#pod Enqueue a new job with C<inactive> state.
#pod
#pod These options are currently available:
#pod
#pod =over 2
#pod
#pod =item delay
#pod
#pod   delay => 10
#pod
#pod Delay job for this many seconds (from now).
#pod
#pod =item priority
#pod
#pod   priority => 5
#pod
#pod Job priority, defaults to C<0>.
#pod
#pod =item queue
#pod
#pod   queue => 'important'
#pod
#pod Queue to put job in, defaults to C<default>.
#pod
#pod =back
#pod
#pod =head2 fail_job
#pod
#pod   my $bool = $backend->fail_job($job_id, $retries);
#pod   my $bool = $backend->fail_job($job_id, $retries, 'Something went wrong!');
#pod   my $bool = $backend->fail_job(
#pod     $job_id, $retries, {msg => 'Something went wrong!'});
#pod
#pod Transition from C<active> to C<failed> state.
#pod
#pod =head2 finish_job
#pod
#pod   my $bool = $backend->finish_job($job_id, $retries);
#pod   my $bool = $backend->finish_job($job_id, $retries, 'All went well!');
#pod   my $bool = $backend->finish_job($job_id, $retries, {msg => 'All went well!'});
#pod
#pod Transition from C<active> to C<finished> state.
#pod
#pod =head2 job_info
#pod
#pod   my $job_info = $backend->job_info($job_id);
#pod
#pod Get information about a job or return C<undef> if job does not exist.
#pod
#pod   # Check job state
#pod   my $state = $backend->job_info($job_id)->{state};
#pod
#pod   # Get job result
#pod   my $result = $backend->job_info($job_id)->{result};
#pod
#pod These fields are currently available:
#pod
#pod =over 2
#pod
#pod =item args
#pod
#pod   args => ['foo', 'bar']
#pod
#pod Job arguments.
#pod
#pod =item created
#pod
#pod   created => 784111777
#pod
#pod Time job was created.
#pod
#pod =item delayed
#pod
#pod   delayed => 784111777
#pod
#pod Time job was delayed to.
#pod
#pod =item finished
#pod
#pod   finished => 784111777
#pod
#pod Time job was finished.
#pod
#pod =item priority
#pod
#pod   priority => 3
#pod
#pod Job priority.
#pod
#pod =item queue
#pod
#pod   queue => 'important'
#pod
#pod Queue name.
#pod
#pod =item result
#pod
#pod   result => 'All went well!'
#pod
#pod Job result.
#pod
#pod =item retried
#pod
#pod   retried => 784111777
#pod
#pod Time job has been retried.
#pod
#pod =item retries
#pod
#pod   retries => 3
#pod
#pod Number of times job has been retried.
#pod
#pod =item started
#pod
#pod   started => 784111777
#pod
#pod Time job was started.
#pod
#pod =item state
#pod
#pod   state => 'inactive'
#pod
#pod Current job state, usually C<active>, C<failed>, C<finished> or C<inactive>.
#pod
#pod =item task
#pod
#pod   task => 'foo'
#pod
#pod Task name.
#pod
#pod =item worker
#pod
#pod   worker => '154'
#pod
#pod Id of worker that is processing the job.
#pod
#pod =back
#pod
#pod =head2 list_jobs
#pod
#pod   my $batch = $backend->list_jobs($offset, $limit);
#pod   my $batch = $backend->list_jobs($offset, $limit, {state => 'inactive'});
#pod
#pod Returns the same information as L</"job_info"> but in batches.
#pod
#pod These options are currently available:
#pod
#pod =over 2
#pod
#pod =item state
#pod
#pod   state => 'inactive'
#pod
#pod List only jobs in this state.
#pod
#pod =item task
#pod
#pod   task => 'test'
#pod
#pod List only jobs for this task.
#pod
#pod =back
#pod
#pod =head2 list_workers
#pod
#pod   my $batch = $backend->list_workers($offset, $limit);
#pod
#pod Returns the same information as L</"worker_info"> but in batches.
#pod
#pod =head2 new
#pod
#pod   my $backend = Minion::Backend::mysql->new('mysql://mysql@/test');
#pod
#pod Construct a new L<Minion::Backend::mysql> object.
#pod
#pod =head2 register_worker
#pod
#pod   my $worker_id = $backend->register_worker;
#pod   my $worker_id = $backend->register_worker($worker_id);
#pod
#pod Register worker or send heartbeat to show that this worker is still alive.
#pod
#pod =head2 remove_job
#pod
#pod   my $bool = $backend->remove_job($job_id);
#pod
#pod Remove C<failed>, C<finished> or C<inactive> job from queue.
#pod
#pod =head2 repair
#pod
#pod   $backend->repair;
#pod
#pod Repair worker registry and job queue if necessary.
#pod
#pod =head2 reset
#pod
#pod   $backend->reset;
#pod
#pod Reset job queue.
#pod
#pod =head2 retry_job
#pod
#pod   my $bool = $backend->retry_job($job_id, $retries);
#pod   my $bool = $backend->retry_job($job_id, $retries, {delay => 10});
#pod
#pod Transition from C<failed> or C<finished> state back to C<inactive>.
#pod
#pod These options are currently available:
#pod
#pod =over 2
#pod
#pod =item delay
#pod
#pod   delay => 10
#pod
#pod Delay job for this many seconds (from now).
#pod
#pod =item priority
#pod
#pod   priority => 5
#pod
#pod Job priority.
#pod
#pod =item queue
#pod
#pod   queue => 'important'
#pod
#pod Queue to put job in.
#pod
#pod =back
#pod
#pod =head2 stats
#pod
#pod   my $stats = $backend->stats;
#pod
#pod Get statistics for jobs and workers.
#pod
#pod =head2 unregister_worker
#pod
#pod   $backend->unregister_worker($worker_id);
#pod
#pod Unregister worker.
#pod
#pod =head2 worker_info
#pod
#pod   my $worker_info = $backend->worker_info($worker_id);
#pod
#pod Get information about a worker or return C<undef> if worker does not exist.
#pod
#pod   # Check worker host
#pod   my $host = $backend->worker_info($worker_id)->{host};
#pod
#pod These fields are currently available:
#pod
#pod =over 2
#pod
#pod =item host
#pod
#pod   host => 'localhost'
#pod
#pod Worker host.
#pod
#pod =item jobs
#pod
#pod   jobs => ['10023', '10024', '10025', '10029']
#pod
#pod Ids of jobs the worker is currently processing.
#pod
#pod =item notified
#pod
#pod   notified => 784111777
#pod
#pod Last time worker sent a heartbeat.
#pod
#pod =item pid
#pod
#pod   pid => 12345
#pod
#pod Process id of worker.
#pod
#pod =item started
#pod
#pod   started => 784111777
#pod
#pod Time worker was started.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Minion>, L<Mojolicious::Guides>, L<http://mojolicio.us>.
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Minion::Backend::mysql

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  use Mojolicious::Lite;

  plugin Minion => {mysql => 'mysql://user@127.0.0.1/minion_jobs'};

  # Slow task
  app->minion->add_task(poke_mojo => sub {
    my $job = shift;
    $job->app->ua->get('mojolicio.us');
    $job->app->log->debug('We have poked mojolicio.us for a visitor');
  });

  # Perform job in a background worker process
  get '/' => sub {
    my $c = shift;
    $c->minion->enqueue('poke_mojo');
    $c->render(text => 'We will poke mojolicio.us for you soon.');
  };

  app->start;

=head1 DESCRIPTION

L<Minion::Backend::mysql> is a backend for L<Minion> based on L<Mojo::mysql>. All
necessary tables will be created automatically with a set of migrations named
C<minion>. This backend requires at least v5.6.5 of MySQL.

=head1 NAME

Minion::Backend::mysql - MySQL backend

=head1 ATTRIBUTES

L<Minion::Backend::mysql> inherits all attributes from L<Minion::Backend> and
implements the following new ones.

=head2 mysql

  my $mysql   = $backend->mysql;
  $backend = $backend->mysql(Mojo::mysql->new);

L<Mojo::mysql> object used to store all data.

=head1 METHODS

L<Minion::Backend::mysql> inherits all methods from L<Minion::Backend> and
implements the following new ones.

=head2 dequeue

  my $job_info = $backend->dequeue($worker_id, 0.5);
  my $job_info = $backend->dequeue($worker_id, 0.5, {queues => ['important']});

Wait for job, dequeue it and transition from C<inactive> to C<active> state or
return C<undef> if queues were empty.

These options are currently available:

=over 2

=item queues

  queues => ['important']

One or more queues to dequeue jobs from, defaults to C<default>.

=back

These fields are currently available:

=over 2

=item args

  args => ['foo', 'bar']

Job arguments.

=item id

  id => '10023'

Job ID.

=item retries

  retries => 3

Number of times job has been retried.

=item task

  task => 'foo'

Task name.

=back

=head2 enqueue

  my $job_id = $backend->enqueue('foo');
  my $job_id = $backend->enqueue(foo => [@args]);
  my $job_id = $backend->enqueue(foo => [@args] => {priority => 1});

Enqueue a new job with C<inactive> state.

These options are currently available:

=over 2

=item delay

  delay => 10

Delay job for this many seconds (from now).

=item priority

  priority => 5

Job priority, defaults to C<0>.

=item queue

  queue => 'important'

Queue to put job in, defaults to C<default>.

=back

=head2 fail_job

  my $bool = $backend->fail_job($job_id, $retries);
  my $bool = $backend->fail_job($job_id, $retries, 'Something went wrong!');
  my $bool = $backend->fail_job(
    $job_id, $retries, {msg => 'Something went wrong!'});

Transition from C<active> to C<failed> state.

=head2 finish_job

  my $bool = $backend->finish_job($job_id, $retries);
  my $bool = $backend->finish_job($job_id, $retries, 'All went well!');
  my $bool = $backend->finish_job($job_id, $retries, {msg => 'All went well!'});

Transition from C<active> to C<finished> state.

=head2 job_info

  my $job_info = $backend->job_info($job_id);

Get information about a job or return C<undef> if job does not exist.

  # Check job state
  my $state = $backend->job_info($job_id)->{state};

  # Get job result
  my $result = $backend->job_info($job_id)->{result};

These fields are currently available:

=over 2

=item args

  args => ['foo', 'bar']

Job arguments.

=item created

  created => 784111777

Time job was created.

=item delayed

  delayed => 784111777

Time job was delayed to.

=item finished

  finished => 784111777

Time job was finished.

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

Time job has been retried.

=item retries

  retries => 3

Number of times job has been retried.

=item started

  started => 784111777

Time job was started.

=item state

  state => 'inactive'

Current job state, usually C<active>, C<failed>, C<finished> or C<inactive>.

=item task

  task => 'foo'

Task name.

=item worker

  worker => '154'

Id of worker that is processing the job.

=back

=head2 list_jobs

  my $batch = $backend->list_jobs($offset, $limit);
  my $batch = $backend->list_jobs($offset, $limit, {state => 'inactive'});

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

  my $batch = $backend->list_workers($offset, $limit);

Returns the same information as L</"worker_info"> but in batches.

=head2 new

  my $backend = Minion::Backend::mysql->new('mysql://mysql@/test');

Construct a new L<Minion::Backend::mysql> object.

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

  my $bool = $backend->retry_job($job_id, $retries);
  my $bool = $backend->retry_job($job_id, $retries, {delay => 10});

Transition from C<failed> or C<finished> state back to C<inactive>.

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

  my $worker_info = $backend->worker_info($worker_id);

Get information about a worker or return C<undef> if worker does not exist.

  # Check worker host
  my $host = $backend->worker_info($worker_id)->{host};

These fields are currently available:

=over 2

=item host

  host => 'localhost'

Worker host.

=item jobs

  jobs => ['10023', '10024', '10025', '10029']

Ids of jobs the worker is currently processing.

=item notified

  notified => 784111777

Last time worker sent a heartbeat.

=item pid

  pid => 12345

Process id of worker.

=item started

  started => 784111777

Time worker was started.

=back

=head1 SEE ALSO

L<Minion>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHORS

=over 4

=item *

Brian Medley <bpmedley@cpan.org>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Alexander Nalobin Dmitry Krylov Olaf Alders Paul Cochrane Zoffix Znet

=over 4

=item *

Alexander Nalobin <nalobin@reg.ru>

=item *

Dmitry Krylov <pentabion@gmail.com>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Paul Cochrane <paul@liekut.de>

=item *

Zoffix Znet <cpan@zoffix.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell and Brian Medley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ minion
-- 1 up
create table if not exists minion_jobs (
		`id`       serial not null primary key,
		`args`     mediumblob not null,
		`created`  timestamp not null default current_timestamp,
		`delayed`  timestamp not null default current_timestamp,
		`finished` timestamp null,
		`priority` int not null,
		`result`   mediumblob,
		`retried`  timestamp null,
		`retries`  int not null default 0,
		`started`  timestamp null,
		`state`    varchar(128) not null default 'inactive',
		`task`     text not null,
		`worker`   bigint
);

create table if not exists minion_workers (
		`id`      serial not null primary key,
		`host`    text not null,
		`pid`     int not null,
		`started` timestamp not null default current_timestamp,
		`notified` timestamp not null default current_timestamp
);

-- 1 down
drop table if exists minion_jobs;
drop table if exists minion_workers;

-- 2 up
create index minion_jobs_state_idx on minion_jobs (state);

-- 3 up
alter table minion_jobs add queue varchar(128) not null default 'default';

-- 4 up
ALTER TABLE minion_workers MODIFY COLUMN started timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE minion_workers MODIFY COLUMN notified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP;
CREATE TABLE IF NOT EXISTS minion_workers_inbox (
  `id` SERIAL NOT NULL PRIMARY KEY,
  `worker_id` BIGINT UNSIGNED NOT NULL,
  `message` BLOB NOT NULL
);
ALTER TABLE minion_jobs ADD COLUMN attempts INT NOT NULL DEFAULT 1;

-- 5 up
ALTER TABLE minion_jobs MODIFY COLUMN args MEDIUMBLOB NOT NULL;
ALTER TABLE minion_jobs MODIFY COLUMN result MEDIUMBLOB;

-- 6 up
ALTER TABLE minion_workers ADD COLUMN status MEDIUMBLOB;
ALTER TABLE minion_jobs ADD COLUMN notes MEDIUMBLOB;
CREATE TABLE IF NOT EXISTS minion_locks (
  id      SERIAL NOT NULL PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  expires TIMESTAMP NOT NULL,
  INDEX (name, expires)
);
DELIMITER //
CREATE FUNCTION minion_lock( $1 VARCHAR(255), $2 INTEGER, $3 INTEGER) RETURNS BOOL
BEGIN
  DECLARE new_expires TIMESTAMP DEFAULT DATE_ADD( NOW(), INTERVAL 1*$2 SECOND );
  DELETE FROM minion_locks WHERE expires < NOW();
  IF (SELECT COUNT(*) >= $3 FROM minion_locks WHERE name = $1)
  THEN
    RETURN FALSE;
  END IF;
  IF new_expires > NOW()
  THEN
    INSERT INTO minion_locks (name, expires) VALUES ($1, new_expires);
  END IF;
  RETURN TRUE;
END
//
DELIMITER ;
CREATE TABLE minion_jobs_depends (
  parent_id BIGINT UNSIGNED NOT NULL,
  child_id BIGINT UNSIGNED NOT NULL,
  FOREIGN KEY (parent_id) REFERENCES minion_jobs(id) ON DELETE CASCADE,
  FOREIGN KEY (child_id) REFERENCES minion_jobs(id) ON DELETE CASCADE
);

-- 6 down
ALTER TABLE minion_workers DROP COLUMN status;
ALTER TABLE minion_jobs DROP COLUMN notes;
DROP TABLE IF EXISTS minion_locks;
DROP FUNCTION IF EXISTS minion_lock;
DROP TABLE minion_jobs_depends;

