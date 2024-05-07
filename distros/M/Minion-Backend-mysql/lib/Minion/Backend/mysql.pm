package Minion::Backend::mysql;

use 5.010;

use Mojo::Base 'Minion::Backend';

use constant DEBUG => $ENV{MINION_BACKEND_DEBUG} || 0;
use Mojo::IOLoop;
use Mojo::JSON qw(encode_json decode_json);
use Mojo::mysql;
use Scalar::Util qw(blessed);
use Sys::Hostname 'hostname';
use Time::Piece ();

has 'mysql';
has 'no_txn' => sub { 0 };

our $VERSION = '1.005';

# The dequeue system has a couple limitations:
# 1. There is no way to directly notify a sleeping worker of an incoming
#    job
# 2. There is a race condition between identifying a runnable job
#    and claiming it for the current worker.
#
# The first is solved by Mojo::mysql::PubSub, which currently makes
# a new connection to MySQL, records the connection ID, and then sleeps. 
# When a message is "published", the publisher writes the message to
# a table and then `KILL`s all the sleeping "subscribers". One of the
# subscribers reads the message from the table and continues.
#
# The second is solved by checking how many rows are `UPDATE`d when
# claiming the job. If none, we try again to dequeue immediately. This
# happens $DEQUEUE_RACE_ATTEMPTS times before giving up.
#
# When it gives up, there may still be jobs available to be dequeued. In
# most cases, this is okay: The worker will start sleeping for an
# incoming job and when one comes in, it will wake up and start
# dequeuing again (even if the new job itself isn't ready to run).
my $DEQUEUE_RACE_ATTEMPTS = 10;

sub dequeue {
  my ($self, $worker_id, $wait, $options) = @_;

  if ((my $job = $self->_try($worker_id, $options))) { return $job }
  return undef if Mojo::IOLoop->is_running;

  my $cb = $self->mysql->pubsub->listen("minion.job" => sub {
    Mojo::IOLoop->stop;
  });

  my $timer = Mojo::IOLoop->timer($wait => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;

  $self->mysql->pubsub->unlisten("minion.job" => $cb) and Mojo::IOLoop->remove($timer);

  return $self->_try($worker_id, $options);
}

sub history {
  my $self = shift;

  my $sql = <<SQL;
SELECT
  MIN(UNIX_TIMESTAMP(jobs.finished)) as `epoch`,
  DAY(jobs.finished) as `day`,
  HOUR(jobs.finished) as `hour`,
  SUM(CASE jobs.state WHEN 'failed' THEN 1 ELSE 0 END) AS failed_jobs,
  SUM(CASE jobs.state WHEN 'finished' THEN 1 ELSE 0 END) AS finished_jobs
FROM minion_jobs jobs
WHERE jobs.finished > SUBTIME(NOW(), '23:00:00')
GROUP BY `day`, `hour`
ORDER BY `day`, `hour`
SQL

  my $data = $self->mysql->db->query($sql)->hashes;

  # Fill in missing hours to create a full time series
  my $now = Time::Piece->new();
  my $current_hour = $now->hour;
  for my $i ( 0..23 ) {
    my $i_hour = ( $current_hour - ( 23 - $i ) ) % 24;
    if ( exists $data->[$i] and $data->[ $i ]{ hour } != $i_hour ) {
      my $epoch = $now->epoch - ( 3600 * ( 24 - $i ) );
      splice @$data, $i, 0, {
        epoch => $epoch - ( $epoch % 3600 ),
        failed_jobs => 0,
        finished_jobs => 0,
      };
    }
    else {
      delete $data->[ $i ]{hour};
      delete $data->[ $i ]{day};
    }
  }

  return {daily => $data};
}

sub enqueue {
  my ($self, $task) = (shift, shift);
  my $args    = shift // [];
  my $options = shift // {};

  # Pre-compute parameters to reduce time holding DB transaction
  my @insert_params = (
    encode_json( $args ),
    $options->{attempts} // 1,
    $options->{delay} // 0,
    ($options->{expire})x2,
    $options->{lax} ? 1 : 0,
    $options->{priority} // 0,
    $options->{queue} // 'default',
    $task,
  );

  my @parents = @{ $options->{parents} // [] };
  my %notes = %{ $options->{notes} // {} };

  my ( $insert_parents_sql, $insert_notes_sql );
  if ( @parents ) {
    $insert_parents_sql = "INSERT IGNORE INTO minion_jobs_depends (`parent_id`, `child_id`) VALUES "
      . join( ", ", map "( ?, ? )", @parents );
  }
  if ( keys %notes ) {
    $insert_notes_sql = 'INSERT INTO minion_notes (`job_id`, `note_key`, `note_value`) VALUES '
      . join( ', ', map '( ?, ?, ? )', keys %notes );
    $notes{ $_ } = encode_json( $notes{ $_ } ) for keys %notes;
  }

  my $db = $self->mysql->db;
  # If we are adding data in related tables, use a transaction to commit
  # the entire job at once. Without this, a job may be started before
  # one of its parents, since the parent restriction is added after the
  # job itself.
  my $tx = (!$insert_notes_sql && !$insert_parents_sql) || $self->no_txn ? undef : $db->begin;

  my $job_id = $db->query(
    "insert into minion_jobs (`args`, `attempts`, `delayed`, `expires`, `lax`, `priority`, `queue`, `task`)
     values (?, ?, (DATE_ADD(NOW(), INTERVAL ? SECOND)), case when ? is not null then date_add( now(), interval ? second ) end, ?, ?, ?, ?)",
     @insert_params,
  )->last_insert_id;

  if ( $insert_parents_sql ) {
    my @insert_parents_params = map { $_, $job_id  } @parents;
    $db->query( $insert_parents_sql, @insert_parents_params );
  }

  if ( $insert_notes_sql ) {
    my @insert_notes_params = map { $job_id, $_, $notes{$_} } keys %notes;
    $db->query( $insert_notes_sql, @insert_notes_params );
  }

  $tx->commit if defined $tx;
  $self->mysql->pubsub->notify("minion.job" => $job_id);

  return $job_id;
}

sub note {
  my ($self, $id, $notes) = @_;

  my @replace_keys = grep defined $notes->{ $_ }, keys %$notes;
  my @delete_keys = grep !defined $notes->{ $_ }, keys %$notes;

  my ( $replaced, $deleted );
  my $db = $self->mysql->db;
  if ( @replace_keys ) {
    local $@; # Don't clobber global
    $replaced = !!eval {
      $db->query(
        'REPLACE INTO minion_notes (`job_id`, `note_key`, `note_value`) VALUES '
        . join( ', ', map '( ?, ?, ? )', @replace_keys ),
        map { $id, $_, encode_json( $notes->{$_} ) } @replace_keys
      )->rows;
    };
  }
  if ( @delete_keys ) {
    $deleted = !!$db->delete(
      minion_notes => {
        job_id => $id,
        note_key => { -in => \@delete_keys },
      }
    )->rows;
  }

  return $replaced || $deleted;
}

sub fail_job   { shift->_update(1, @_) }
sub finish_job { shift->_update(0, @_) }

sub list_jobs {
  my ($self, $offset, $limit, $options) = @_;

  my ( @where, @params );
  if ( my $states = $options->{states} ) {
    push @where, 'j.state in (' . join( ',', ('?') x @$states ) . ')';
    push @params, @$states;
  }
  if ( my $queues = $options->{queues} ) {
    push @where, 'j.queue in (' . join( ',', ('?') x @$queues ) . ')';
    push @params, @$queues;
  }
  if ( my $tasks = $options->{tasks} ) {
    push @where, 'j.task in (' . join( ',', ('?') x @$tasks ) . ')';
    push @params, @$tasks;
  }
  if ( my $ids = $options->{ids} ) {
    push @where, 'j.id in (' . join( ',', ('?') x @$ids ) . ')';
    push @params, @$ids;
  }
  if ( my $id = $options->{before} ) {
    push @where, 'j.id < ?';
    push @params, $id;
  }
  if ( my $notes = $options->{notes} ) {
    push @where, '( '
      . join( ' or ', ('? in ( select minion_notes.note_key from minion_notes where minion_notes.job_id=j.id )')x@$notes )
      . ' )';
    push @params, @$notes;
  }

  push @where, q{(j.state != 'inactive' or j.expires is null or j.expires > now())};
  my $where = @where ? 'WHERE ' . join( ' AND ', @where ) : '';

  my $db = $self->mysql->db;

  my $list_sql = qq{
    SELECT
      minion_jobs.id, minion_jobs.args, minion_jobs.attempts,
      minion_jobs.state, minion_jobs.task, minion_jobs.worker,
      minion_jobs.lax, minion_jobs.priority, minion_jobs.queue,
      minion_jobs.result, minion_jobs.retries,
      filtered.children, filtered.parents,
      UNIX_TIMESTAMP(minion_jobs.created) AS created,
      UNIX_TIMESTAMP(minion_jobs.`delayed`) AS `delayed`,
      UNIX_TIMESTAMP(minion_jobs.finished) AS finished,
      UNIX_TIMESTAMP(minion_jobs.retried) AS retried,
      UNIX_TIMESTAMP(minion_jobs.started) AS started,
      UNIX_TIMESTAMP(NOW()) AS time,
      UNIX_TIMESTAMP(minion_jobs.expires) AS expires
    FROM minion_jobs
    JOIN (
      SELECT j.id,
        GROUP_CONCAT( child_jobs.child_id ORDER BY child_jobs.child_id SEPARATOR ':' ) AS children,
        GROUP_CONCAT( parent_jobs.parent_id ORDER BY parent_jobs.parent_id SEPARATOR ':' ) AS parents
      FROM minion_jobs j
      LEFT JOIN minion_jobs_depends child_jobs ON j.id=child_jobs.parent_id
      LEFT JOIN minion_jobs_depends parent_jobs ON j.id=parent_jobs.child_id
      $where
      GROUP BY j.id
    ) filtered USING ( id )
    ORDER BY minion_jobs.id DESC
    LIMIT ? OFFSET ?
  };

  my $jobs = $db->query( $list_sql, @params, $limit, $offset )->hashes;
  $jobs->map( _decode_json_fields(qw{ args result }) )
    ->each( sub {
      $_->{children} = [ split /:/, $_->{children} // '' ];
      $_->{parents} = [ split /:/, $_->{parents} // '' ];
      $_->{notes} = {
        $db->select( minion_notes => [qw( note_key note_value )], { job_id => $_->{id} } )
        ->arrays->map(sub{ $_->[0], decode_json( $_->[1] ) })->each
      };
    } );

  # ; use Data::Dumper;
  # ; say Dumper $jobs;

  my $total = $db->query(
    qq{SELECT COUNT(*) AS count FROM minion_jobs j $where}, @params
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
  if ( my $id = $options->{before} ) {
    push @where, 'id < ?';
    push @params, $id;
  }

  my $db = $self->mysql->db;

  my $where = @where ? 'WHERE ' . join ' AND ', @where : '';
  my $sql = "SELECT
    id, UNIX_TIMESTAMP(notified) AS notified, host, pid,
    UNIX_TIMESTAMP(started) AS started, status
  FROM minion_workers $where ORDER BY id DESC LIMIT ? OFFSET ?";
  my $workers = $db->query($sql, @params, $limit, $offset)
    ->hashes;

  # Add jobs to each worker
  my $jobs_sql = q{SELECT id FROM minion_jobs WHERE state='active' AND worker=?};
  $workers->map( sub {
      $_->{status} = decode_json( $_->{status} );
      $_->{jobs} = $db->query($jobs_sql, $_->{id})->arrays->flatten->to_array
  } );

  my $total = $db->query(
    qq{SELECT COUNT(*) AS count FROM minion_workers $where}, @params
  )->hash->{count};

  return {
    workers => $workers,
    total => $total,
  };
}

sub list_locks {
  my ($self, $offset, $limit, $options) = @_;

  my ( @where, @params );
  if ( my $name = $options->{names} // $options->{name} ) {
    my @names = ref $name eq 'ARRAY' ? @$name : ( $name );
    push @where, 'name in (' . join( ',', ('?') x @names ) . ')';
    push @params, @names;
  }

  push @where, 'expires > now()';

  my $where = @where ? 'WHERE ' . join ' AND ', @where : '';
  my $sql = "SELECT
          id, name, UNIX_TIMESTAMP(expires) AS expires
      FROM minion_locks
      $where
      ORDER BY id
      DESC LIMIT ? OFFSET ?";

  my $db = $self->mysql->db;

  my $locks = $db->query($sql, @params, $limit || 0, $offset || 0)->hashes;

  my $total = $db->query(
    "SELECT COUNT(name) AS total FROM minion_locks $where", @params
  )->hash->{total};

  return {
    locks => $locks,
    total => $total,
  };
}

sub new {
  my ( $class, @args ) = @_;
  state $skip_migration = 0;

  my $mysql;
  my $force_migration = 0;
  if ( @args == 1 && blessed($args[0]) && $args[0]->isa('Mojo::mysql') ) {
    $mysql = $args[0];
    # We need to force an immediate migration if given a Mojo::mysql
    # object, because the user may decide to add another migration after
    # adding the Minion plugin.
    $force_migration = 1;
  }
  else {
    if ( ref $args[0] eq 'HASH' ) {
      @args = %{ $args[0] };
    }
    $mysql = Mojo::mysql->new(@args);
  }

  my $self = $class->SUPER::new(mysql => $mysql);

  if ( !$skip_migration ) {
    if ($force_migration) {

      # First make sure any impending migrations happen
      # before we overwrite them:
      $mysql->migrations->migrate;

      # Then load this module's migrations and run them:
      $mysql->migrations->name('minion')->from_data;
      $mysql->migrations->migrate;
    }
    else {
      # Load this module's migrations and run them
      # the first time a DB connection is attempted:
      $mysql->migrations->name('minion')->from_data;
      $mysql->once(connection => sub {
          my ( $mysql ) = @_;
          $mysql->migrations->migrate;
      });
    }
  }

  return $self;
}

sub register_worker {
  my ($self, $id, $options) = @_;

  my $db = $self->mysql->db;
  my $sql = q{INSERT INTO minion_workers (id, host, pid, status)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE notified=NOW(), host=VALUES(host), pid=VALUES(pid), status=VALUES(status)};
  my $res = $db->query($sql, $id, hostname, $$, encode_json( $options->{status} // {} ) );

  return $id // $res->last_insert_id;
}

sub remove_job {
  !!shift->mysql->db->query(
    "delete minion_jobs, minion_jobs_depends from minion_jobs
     left join minion_jobs_depends
        on minion_jobs.id = minion_jobs_depends.parent_id
     where minion_jobs.id = ? and minion_jobs.state in ('inactive', 'failed', 'finished')",
     shift
  )->{affected_rows};
}

sub repair {
  my $self = shift;

  # Workers without heartbeats
  my $db     = $self->mysql->db;
  my $minion = $self->minion;
  $db->query(
    "delete from minion_workers
     where notified < DATE_SUB(NOW(), INTERVAL ? SECOND)",
     $minion->missing_after
  );

  # Old jobs with no unresolved dependencies
  $db->query(
    q{
      DELETE job
      FROM minion_jobs job
      LEFT JOIN minion_jobs_depends depends ON depends.parent_id = job.id
      LEFT JOIN minion_jobs child ON child.id = depends.child_id AND child.state != 'finished'
      WHERE job.state = 'finished'
        AND job.`finished` <= DATE_SUB(NOW(), INTERVAL ? SECOND)
        AND child.id IS NULL
    },
    $minion->remove_after,
  );

  # Old expired jobs
  $db->query(
    q{
      DELETE FROM minion_jobs
      WHERE state = 'inactive' AND expires <= NOW()
    },
  );

  # Jobs with missing worker (can be retried)
  $db->query(
    "select job.id, job.retries from minion_jobs job
     left join minion_workers worker on job.worker = worker.id
     where job.state = 'active' and job.queue != 'minion_foreground'
       and worker.id is null"
  )->hashes->each(sub { $self->fail_job(@$_{qw(id retries)}, 'Worker went away') });

  # Jobs in queue without workers or not enough workers (cannot be retried and requires admin attention)
  $db->query(
    q{update minion_jobs set state = 'failed', result = '"Job appears stuck in queue"'
      where state = 'inactive' and DATE_ADD( `delayed`, interval ? second ) < now()}, $minion->stuck_after
  );

}

sub reset {
  my ($self, $options) = (shift, shift // {});

  my $db = $self->mysql->db;
  if ( $options->{all} ) {
    $db->query("delete from minion_jobs");
    $db->query("ALTER TABLE minion_jobs AUTO_INCREMENT = 1");
    $db->query("truncate table minion_locks");
    $db->query("ALTER TABLE minion_locks AUTO_INCREMENT = 1");
    $db->query("truncate table minion_jobs_depends");
    $db->query("truncate table minion_notes");
    $db->query("DELETE FROM minion_workers");
    $db->query("ALTER TABLE minion_workers AUTO_INCREMENT = 1");
  }
  elsif ( $options->{locks} ) {
    $db->query("truncate table minion_locks");
    $db->query("ALTER TABLE minion_locks AUTO_INCREMENT = 1");
  }
}

sub lock {
  my ($self, $name, $duration, $options) = (shift, shift, shift, shift // {});
  return !!$self->mysql->db->query('SELECT minion_lock(?, ?, ?)',
    $name, $duration, $options->{limit} || 1)->array->[0];
}

sub unlock {
  !!shift->mysql->db->query(
    'DELETE FROM minion_locks
      WHERE expires > NOW() AND name = ? ORDER BY EXPIRES
      LIMIT 1', shift
  )->rows;
}

sub retry_job {
  my ($self, $id, $retries) = (shift, shift, shift);
  my $db = $self->mysql->db;
  my $options = shift // {};

  if ( my $parents = delete $options->{ parents } ) {
    $db->query(
      'DELETE FROM `minion_jobs_depends` WHERE child_id=?',
      $id,
    );
    if ( @$parents ) {
      $db->query(
        "INSERT INTO minion_jobs_depends (`parent_id`, `child_id`) VALUES "
        . join( ", ", map "( ?, ? )", @$parents ),
        map { $_, $id  } @$parents
      );
    }
  }

  return !!$db->query(
    "UPDATE `minion_jobs`
     SET attempts = COALESCE(?, attempts),
       `delayed` = DATE_ADD(NOW(), INTERVAL ? SECOND),
       expires = case when ? is not null then date_add( now(), interval ? second ) else expires end,
       lax = coalesce(?, lax),
       priority = COALESCE(?, priority), queue = COALESCE(?, queue),
       retried = NOW(), retries = retries + 1, state = 'inactive'
     WHERE id = ? AND retries = ?",
     $options->{attempts}, $options->{delay} // 0, ($options->{expire})x2,
     exists $options->{lax} ? $options->{lax} ? 1 : 0 : undef,
     @$options{qw(priority queue)}, $id, $retries
  )->{affected_rows};
}

sub stats {
  my $self = shift;

  my %stats = map { $_ => 0 } qw(
    active_workers inactive_workers active_jobs inactive_jobs failed_jobs finished_jobs
    enqueued_jobs delayed_jobs active_locks uptime
  );

  my $db = $self->mysql->db;

  # Worker statistics
  my $worker_sql = q{
    SELECT
      SUM(job.id IS NOT NULL) AS is_active
    FROM minion_workers worker
    LEFT JOIN minion_jobs job
        ON worker.id = job.worker
        AND job.state = 'active'
    GROUP BY worker.id
  };
  my $res = $db->query( $worker_sql );
  while ( my $row = $res->hash ) {
    $stats{ $row->{is_active} ? 'active_workers' : 'inactive_workers' }++;
  }

  # Job statistics
  my $job_sql = q{
    SELECT
        minion_jobs.state,
        COUNT(minion_jobs.state) AS jobs,
        SUM(minion_jobs.`delayed` > NOW()) AS `delayed`
    FROM minion_jobs
    GROUP BY minion_jobs.state
  };
  $res = $db->query( $job_sql );
  while ( my $row = $res->hash ) {
    my $state = $row->{state};
    $stats{ "${state}_jobs" } += $row->{jobs};
    $stats{ enqueued_jobs } += $row->{jobs};
    if ( $state eq 'inactive' ) {
      $stats{ delayed_jobs } += $row->{delayed};
    }
  }

  $stats{active_locks} = $db->query("SELECT COUNT(*) FROM minion_locks WHERE expires > now()")->array->[0];
  $stats{uptime} = $db->query( "SHOW GLOBAL STATUS LIKE 'Uptime'" )->hash->{Value};

  return \%stats;
}

sub unregister_worker {
  shift->mysql->db->query('delete from minion_workers where id = ?', shift);
}

sub _try {
  my ($self, $worker_id, $options) = @_;

  my $tasks = [keys %{$self->minion->tasks}];

  return unless @$tasks;

  my $queues = $options->{queues} // ['default'];

  my $qq = join ", ", map({ "?" } @$queues);
  my $qt = join ", ", map({ "?" } @$tasks );
  my @bind_vars = ( @$queues, @$tasks );

  my $sql_job_id = '';
  if ( defined $options->{id} ) {
    $sql_job_id = 'AND job.id = ?';
    push @bind_vars, $options->{id};
  }

  # The dependencies table stores a copy of the parent job's state and
  # expiration (updated automatically via triggers). We use this to roll
  # up a count of pending and failed parent jobs for the current child
  # job. If there are no pending jobs, or if the current child job is
  # "lax" and there are only failed jobs, the child job is ready.
  # An expired job is considered "failed" for this check.
  my $sql = qq{
    SELECT job.id, job.args, job.retries, job.task
    FROM minion_jobs job
    LEFT JOIN (
        SELECT depends.child_id, COUNT(depends.child_id) AS pending,
            COALESCE( SUM(depends.state = 'failed' OR (depends.expires IS NOT NULL AND depends.expires <= NOW())), 0 ) AS failed
        FROM minion_jobs_depends depends
        WHERE depends.state IS NOT NULL AND (
            depends.state = 'active'
            OR ( depends.state = 'failed' )
            OR ( depends.state = 'inactive' AND (depends.expires IS NULL OR depends.expires > NOW()))
        )
        GROUP BY depends.child_id
    ) depends ON depends.child_id = job.id
    WHERE job.state = 'inactive'
      AND job.`delayed` <= NOW()
      AND job.queue IN ($qq) AND job.task IN ($qt)
      $sql_job_id
      AND (job.expires IS NULL OR job.expires > NOW())
      AND (
        depends.pending IS NULL
        OR ( depends.pending = depends.failed AND job.lax )
      )
    ORDER BY job.priority DESC, job.created
    LIMIT 1
  };

  warn "Dequeuing SQL: $sql" if DEBUG;
  my $db = $self->mysql->db;
  my $i = $DEQUEUE_RACE_ATTEMPTS;
  my $job;
  while ( $i-- > 0 ) {
    # Find a candidate job to run
    my $res = $db->query( $sql, @bind_vars )->hash;
    return unless $res; # No jobs ready to work on

    # Try to claim the job for this worker. There is a race condition
    # between selecting the job and claiming it, so we need to make sure
    # we were the one to claim it.
    my $claimed = $db->query(
      qq{ UPDATE minion_jobs SET started = NOW(), state = 'active', worker = ? WHERE id = ? AND state = 'inactive' },
      $worker_id, $res->{id},
    )->affected_rows;

    # Try again if we lose the race
    next if !$claimed;

    # Won the race, so do the job
    $job = $res;
    last;
  }

  return undef unless $job;
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

  return 1 if !$fail;    # finished

  my $job = $self->list_jobs( 0, 1, { ids => [$id] } )->{jobs}[0];
  return $fail ? $self->auto_retry_job($id, $retries, $job->{attempts}) : 1;
}

sub broadcast {
  my ($self, $command, $args, $ids) = (shift, shift, shift || [], shift || []);

  my $db = $self->mysql->db;

  my $message = encode_json( [ $command, @$args ] );
  if ( !@$ids ) {
    @$ids = map { $_->{id} }
      @{ $db->query( 'SELECT id FROM minion_workers' )->hashes },
  }
  my $rows = 0;
  for my $id ( @$ids ) {
    $rows += $db->query(
      'INSERT INTO minion_workers_inbox ( worker_id, message ) VALUES ( ?, ? )',
      $id, $message,
    )->rows;
  }
  return $rows;
}

sub receive {
  my ($self, $worker_id) = @_;
  #; use Data::Dumper;
  my $db = $self->mysql->db;
  my $rows = $db->query(
    'SELECT id, message FROM minion_workers_inbox WHERE worker_id=?', $worker_id,
  )->hashes;
  return [] unless $rows && @$rows;
  #; say Dumper $rows;
  my @ids = map { $_->{id} } @$rows;
  #; say Dumper \@ids;
  $db->query(
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
#pod =head2 no_txn
#pod
#pod If true, will not make a transaction around the L</enqueue> insertions
#pod when a job has parent jobs. Without a transaction, the job could be
#pod dequeued before its parent relationships are written to the database.
#pod However, since MySQL does not support nested transactions (despite
#pod supporting something almost exactly like them...), you can disable
#pod transactions for testing by setting this attribute (if you perform your
#pod tests in a transaction so they can be rolled back when the test is
#pod complete).
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
#pod   my $batch = $backend->list_jobs($offset, $limit, {states => 'inactive'});
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
#pod =item parents
#pod
#pod   parents => [$id1, $id2, $id3]
#pod
#pod Jobs this job depends on.
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
#pod =head1 ERRORS
#pod
#pod =head2 DBD::mysql::st execute failed: Table '*.minion_workers' doesn't exist
#pod
#pod This may happen when the SQL create/upgrade scripts fail to run
#pod completely due to permission errors. Re-running with the environment
#pod variable C<MOJO_MIGRATIONS_DEBUG=1> should produce the error message
#pod returned by the database.
#pod
#pod A common reason for the database install to fail on MySQL >= 8 is that
#pod the user installing the database does not have C<SUPER> privileges
#pod needed to create functions when binlogs are enabled: (C<DBD::mysql::st
#pod execute failed: You do not have the SUPER privilege and binary logging
#pod is enabled>). See L<the MySQL documentation for Stored Program Binary
#pod Logging|https://dev.mysql.com/doc/refman/8.0/en/stored-programs-logging.html>
#pod for more information about this problem and how to correct it.
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

version 1.005

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

=head2 no_txn

If true, will not make a transaction around the L</enqueue> insertions
when a job has parent jobs. Without a transaction, the job could be
dequeued before its parent relationships are written to the database.
However, since MySQL does not support nested transactions (despite
supporting something almost exactly like them...), you can disable
transactions for testing by setting this attribute (if you perform your
tests in a transaction so they can be rolled back when the test is
complete).

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
  my $batch = $backend->list_jobs($offset, $limit, {states => 'inactive'});

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

=item parents

  parents => [$id1, $id2, $id3]

Jobs this job depends on.

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

=head1 ERRORS

=head2 DBD::mysql::st execute failed: Table '*.minion_workers' doesn't exist

This may happen when the SQL create/upgrade scripts fail to run
completely due to permission errors. Re-running with the environment
variable C<MOJO_MIGRATIONS_DEBUG=1> should produce the error message
returned by the database.

A common reason for the database install to fail on MySQL >= 8 is that
the user installing the database does not have C<SUPER> privileges
needed to create functions when binlogs are enabled: (C<DBD::mysql::st
execute failed: You do not have the SUPER privilege and binary logging
is enabled>). See L<the MySQL documentation for Stored Program Binary
Logging|https://dev.mysql.com/doc/refman/8.0/en/stored-programs-logging.html>
for more information about this problem and how to correct it.

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

=for stopwords a-leelan Alexander Nalobin Dmitry Krylov Hu Yin Jason A. Crome Larry Leszczynski Olaf Alders Paul Cochrane Peter Joh Sergey Andreev Zoffix Znet

=over 4

=item *

a-leelan <40534142+a-leelan@users.noreply.github.com>

=item *

Alexander Nalobin <nalobin@reg.ru>

=item *

Dmitry Krylov <pentabion@gmail.com>

=item *

Hu Yin <huyin8@gmail.com>

=item *

Jason A. Crome <jcrome@empoweredbenefits.com>

=item *

Larry Leszczynski <larryl@cpan.org>

=item *

Larry Leszczynski <larryl@emailplus.org>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Paul Cochrane <paul@liekut.de>

=item *

Peter Joh <peter.joh@grantstreet.com>

=item *

Sergey Andreev <40195653+saintserge@users.noreply.github.com>

=item *

Zoffix Znet <cpan@zoffix.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell and Brian Medley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ minion
-- 13 up
CREATE TABLE IF NOT EXISTS minion_jobs (
  `id`       BIGINT NOT NULL AUTO_INCREMENT UNIQUE,
  `args`     MEDIUMBLOB NOT NULL,
  `created`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `delayed`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished` TIMESTAMP NULL,
  `priority` INT NOT NULL,
  `result`   MEDIUMBLOB,
  `attempts` INT NOT NULL DEFAULT 1,
  `retried`  TIMESTAMP NULL,
  `retries`  INT NOT NULL DEFAULT 0,
  `started`  TIMESTAMP NULL,
  `expires`  DATETIME,
  `state`    ENUM('inactive','active','finished','failed') NOT NULL DEFAULT 'inactive',
  `lax`      BOOLEAN NOT NULL DEFAULT FALSE,
  `task`     VARCHAR(50) NOT NULL,
  `queue`    VARCHAR(128) NOT NULL DEFAULT 'default',
  `worker`   BIGINT
);

CREATE TABLE IF NOT EXISTS minion_jobs_depends (
  parent_id BIGINT NOT NULL,
  child_id BIGINT NOT NULL,
  state ENUM('inactive','active','finished','failed') NOT NULL DEFAULT 'inactive',
  expires DATETIME,
  FOREIGN KEY (child_id) REFERENCES minion_jobs(id) ON DELETE CASCADE,
  PRIMARY KEY (parent_id, child_id)
);
CREATE TRIGGER minion_trigger_insert_depends BEFORE INSERT ON minion_jobs_depends FOR EACH ROW
  SET NEW.state = COALESCE(( SELECT state FROM minion_jobs WHERE id=NEW.parent_id ), 'finished'),
    NEW.expires = ( SELECT expires FROM minion_jobs WHERE id=NEW.parent_id );
CREATE TRIGGER minion_trigger_update_jobs AFTER UPDATE ON minion_jobs FOR EACH ROW
  UPDATE minion_jobs_depends SET state=NEW.state, expires=NEW.expires WHERE parent_id=OLD.id;

CREATE TABLE IF NOT EXISTS minion_notes (
  job_id BIGINT NOT NULL,
  note_key VARCHAR(191) NOT NULL,
  note_value TEXT,
  PRIMARY KEY (job_id, note_key),
  FOREIGN KEY (job_id) REFERENCES minion_jobs(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS minion_workers (
  `id`      BIGINT AUTO_INCREMENT PRIMARY KEY,
  `host`    TEXT NOT NULL,
  `pid`     INT NOT NULL,
  `started` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notified` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` MEDIUMBLOB
);

CREATE TABLE IF NOT EXISTS minion_workers_inbox (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
  `worker_id` BIGINT NOT NULL,
  `message` BLOB NOT NULL,
  FOREIGN KEY (worker_id) REFERENCES minion_workers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS minion_locks (
  id      SERIAL NOT NULL PRIMARY KEY,
  -- InnoDB index prefix limit is 767 bytes, and if you're using utf8mb4
  -- that makes 767/4 = 191 characters
  name    VARCHAR(191) NOT NULL,
  expires TIMESTAMP NOT NULL,
  INDEX (name, expires)
);
DELIMITER //
CREATE FUNCTION minion_lock( $1 VARCHAR(191), $2 INTEGER, $3 INTEGER) RETURNS BOOL
  NOT DETERMINISTIC MODIFIES SQL DATA SQL SECURITY INVOKER
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

CREATE INDEX minion_jobs_state_idx ON minion_jobs (state, priority DESC, created);
CREATE INDEX minion_jobs_depends_state_expires ON minion_jobs_depends (state, expires);
CREATE INDEX minion_jobs_stats_idx ON minion_jobs (state, `delayed`);

-- 13 down
DROP TRIGGER minion_trigger_insert_depends;
DROP TRIGGER minion_trigger_update_jobs;
DROP TABLE IF EXISTS minion_locks;
DROP TABLE IF EXISTS minion_workers_inbox;
DROP TABLE IF EXISTS minion_workers;
DROP TABLE IF EXISTS minion_notes;
DROP TABLE IF EXISTS minion_jobs_depends;
DROP TABLE IF EXISTS minion_jobs;
DROP FUNCTION minion_lock;

-- 14 up
ALTER TABLE minion_jobs ADD CONSTRAINT minion_jobs_pk_id PRIMARY KEY (id), ALGORITHM=INPLACE, LOCK=NONE;

-- 14 down
ALTER TABLE minion_jobs DROP PRIMARY KEY;

-- 15 up
DROP INDEX id ON minion_jobs;

-- 15 down
CREATE UNIQUE INDEX id ON minion_jobs(id);

-- 16 up
CREATE INDEX minion_jobs_state_finished_idx ON minion_jobs (state, finished) ALGORITHM=INPLACE LOCK=NONE;

-- 16 down
DROP INDEX minion_jobs_state_finished_idx ON minion_jobs;
