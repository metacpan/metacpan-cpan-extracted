package Minion::Backend::Redis;
use Mojo::Base 'Minion::Backend';

use Carp 'croak';
use Digest::SHA 'sha256_base64';
use List::Util 'any';
use Mojo::IOLoop;
use Mojo::JSON qw(from_json to_json);
use Mojo::Redis;
use Mojo::Util 'encode';
use Sort::Versions 'versioncmp';
use Sys::Hostname 'hostname';
use Time::HiRes 'time';

use Data::Dumper;

our $VERSION = '0.003';

has 'redis';

sub new {
    my $self = shift->SUPER::new( redis => Mojo::Redis->new(@_) );

    my $redis_version =
      $self->redis->db->info_structured('server')->{redis_version};
    croak 'Redis Server 2.8.0 or later is required'
      if versioncmp( $redis_version, '2.8.0' ) == -1;

    return $self;
}

sub broadcast {
    my ( $self, $command, $args, $ids ) =
      ( shift, shift, shift || [], shift || [] );
    my $item = to_json( [ $command, @$args ] );
    my %worker_ids =
      map { ( $_ => 1 ) } @{ $self->redis->db->smembers('minion.workers') };
    $ids =
      @$ids
      ? [ grep { exists $worker_ids{$_} } @$ids ]
      : [ keys %worker_ids ];
    my $redis = $self->redis->db;
    $redis->multi;
    $redis->rpush( "minion.worker.$_.inbox", $item ) for @$ids;
    $redis->exec;
    return !!@$ids;
}

sub dequeue {
    my ( $self, $id, $wait, $options ) = @_;

    if ( ( my $job = $self->_try( $id, $options ) ) ) { return $job }
    return undef if Mojo::IOLoop->is_running;

    my $pubsub = $self->redis->pubsub;
    $pubsub->listen( "minion.job" => sub { Mojo::IOLoop->stop } );
    my $timer = Mojo::IOLoop->timer( $wait => sub { Mojo::IOLoop->stop } );
    Mojo::IOLoop->start;
    $pubsub->unlisten('minion.job') and Mojo::IOLoop->remove($timer);
    undef $pubsub;

    return $self->_try( $id, $options );
}

sub enqueue {
    my ( $self, $task, $args, $options ) =
      ( shift, shift, shift || [], shift || {} );

    my $id = $self->redis->db->incr('minion.last_job_id');

    my %notes = %{ $options->{notes} || {} };
    $_ = to_json($_) for values %notes;
    my $parents  = $options->{parents} || [];
    my $queue    = $options->{queue} // 'default';
    my $attempts = $options->{attempts} // 1;
    my $priority = $options->{priority} // 0;
    my $now      = time;
    my $delayed  = $now + ( $options->{delay} // 0 );

    my $redis = $self->redis->db;
    $redis->multi;
    $redis->hmset(
        "minion.job.$id",
        id       => $id,
        args     => to_json($args),
        attempts => $attempts,
        created  => $now,
        delayed  => $delayed,
        parents  => to_json($parents),
        priority => $priority,
        queue    => $queue,
        retries  => 0,
        state    => 'inactive',
        task     => $task,
    );

    $redis->hmset( "minion.job.$id.notes", %notes ) if %notes;
    $redis->sadd( "minion.job.$id.parents", @$parents ) if @$parents;
    $redis->sadd( "minion.job.$_.children", $id ) for @$parents;

    $redis->sadd( "minion.job_queue.$queue",                 $id );
    $redis->sadd( 'minion.job_state.inactive',               $id );
    $redis->sadd( 'minion.job_state.inactive,active,failed', $id );
    $redis->sadd( "minion.job_task.$task",                   $id );
    $redis->sadd( 'minion.jobs',                             $id );

    my $alphaid = sprintf '%012d', $id;
    $redis->zadd( "minion.inactive_job_queue.$queue",
        ( 0 - $priority ) => $alphaid );
    $redis->zadd( "minion.inactive_job_task.$task", 0        => $alphaid );
    $redis->zadd( 'minion.inactive_job_delayed',    $delayed => $id );

    $redis->exec;

    $self->_notify_job if $delayed <= $now;

    return $id;
}

sub fail_job   { shift->_update( 1, @_ ) }
sub finish_job { shift->_update( 0, @_ ) }

sub history {
    my $self = shift;

    my $db = $self->redis->db;

    # TODO: Not implemented.
    my @daily_ordered = [];
    return { daily => \@daily_ordered };
}

sub list_jobs {
    my ( $self, $offset, $limit, $options ) = @_;

    my $redis = $self->redis->db;
    $redis->multi;
    my @sets = (
        'minion.jobs',
        map    { "minion.job_$_.$options->{$_}" }
          grep { defined $options->{$_} } qw(queue state task)
    );
    if ( defined( my $ids = $options->{ids} ) ) {
        my $key = 'minion.temp.jobs.' . join( ',', @$ids );
        $redis->del($key);
        $redis->sadd( $key, @$ids ) if @$ids;
        $redis->expire( $key, 60 );
        push @sets, $key;
    }

    if ( defined( my $notes = $options->{notes} ) ) {
        croak 'Listing jobs by existence of notes is unimplemented';
    }

    my $jobs_hash = sha256_base64( join '$', $$, time );
    my $jobs_key  = "minion.temp.list_jobs.$jobs_hash";
    $redis->sinterstore( $jobs_key, @sets );
    $redis->expire( $jobs_key, 60 );
    $redis->exec;

    my $job_ids = $redis->sort( $jobs_key, LIMIT => $offset, $limit, 'DESC' );
    my $total   = $redis->scard($jobs_key);

    my @jobs;
    foreach my $id (@$job_ids) {

        my %job_info = %{ $redis->hgetall("minion.job.$id") };
        my $children = $redis->smembers("minion.job.$id.children");
        my %notes    = %{ $redis->hgetall("minion.job.$id.notes") };
        $_ = from_json($_) for values %notes;

        if ( defined( my $states = $options->{states} ) ) {
            unless ( grep { $_ eq $job_info{state} } @$states ) {
                next;
            }
        }

        push @jobs,
          {
            id       => $job_info{id},
            args     => from_json( $job_info{args} // 'null' ),
            attempts => $job_info{attempts},
            children => $children,
            created  => $job_info{created},
            delayed  => $job_info{delayed},
            finished => $job_info{finished},
            notes    => \%notes,
            parents  => from_json( $job_info{parents} // 'null' ),
            priority => $job_info{priority},
            queue    => $job_info{queue},
            result   => from_json( $job_info{result} // 'null' ),
            retried  => $job_info{retried},
            retries  => $job_info{retries},
            started  => $job_info{started},
            state    => $job_info{state},
            task     => $job_info{task},
            worker   => $job_info{worker},
          };
    }
    return { jobs => \@jobs, total => $total };
}

sub list_locks {
    my ( $self, $offset, $limit, $options ) = @_;

    my $redis = $self->redis->db;
    my $keys  = $redis->keys('minion.lock.*');
    my @locks;
    foreach my $name (@$keys) {

        my $jobname = substr( $name, 12 );

        # Filter out the job if the name is wrong
        if ( defined( my $names = $options->{names} ) ) {
            my %split_names = map { $_ => 1 } @$names;
            unless ( exists( $split_names{$jobname} ) ) { next; }
        }

        my %named_locks =
          @{ $redis->zrangebyscore( $name, '-inf', '+inf', 'WITHSCORES' ) };

        foreach my $lock_id ( keys %named_locks ) {

            # Craft lock info hashes by hand.
            push @locks,
              {
                name    => $jobname,
                expires => $named_locks{$lock_id}
              };
        }
    }

    # Reorder locks by expiration date
    @locks = sort { $a->{expires} cmp $b->{expires} } @locks;
    my $total = scalar @locks;

    if ( $offset > 0 ) {
        splice( @locks, 0, $offset );
    }

    if ( $limit > 0 ) {
        splice( @locks, $limit );
    }

    return { locks => \@locks, total => $total };
}

sub list_workers {
    my ( $self, $offset, $limit, $options ) = @_;

    my $worker_ids = $self->redis->db->sort(
        'minion.workers',
        LIMIT => $offset,
        $limit, 'DESC'
    );
    my $total = $self->redis->db->scard('minion.workers');

    my @workers;
    foreach my $id (@$worker_ids) {

        my %worker_info = %{ $self->redis->db->hgetall("minion.worker.$id") };

        my $notified =
          $self->redis->db->zscore( 'minion.worker_notified', $id );
        my $jobs = $self->redis->db->sinter( "minion.worker.$id.jobs",
            'minion.job_state.active' );

        push @workers,
          {
            id       => $worker_info{id},
            notified => $notified,
            jobs     => $jobs,
            host     => $worker_info{host},
            pid      => $worker_info{pid},
            status   => from_json( $worker_info{status} // 'null' ),
            started  => $worker_info{started},
          };
    }

    return { total => $total, workers => \@workers };
}

sub lock {
    my ( $self, $name, $duration, $options ) =
      ( shift, shift, shift, shift // {} );
    $self->redis->db->zremrangebyscore( "minion.lock.$name", '-inf',
        '(' . time );
    my $redis = $self->redis->db;
    my $locks = $redis->zcard("minion.lock.$name");

    $redis->watch("minion.lock.$name");
    $redis->multi;
    return !!0 if $locks >= ( $options->{limit} || 1 );

    if ( defined $duration and $duration > 0 ) {
        $self->redis->db->incr('minion.last_lock_id');
        my @lock_id = @{ $redis->exec };
        $redis->zadd( "minion.lock.$name", time + $duration, $lock_id[0] );
    }
    return !!1;
}

sub note {
    my ( $self, $id, $merge ) = @_;
    my $redis = $self->redis->db;
    return !!0 unless $redis->exists("minion.job.$id");
    $redis->watch("minion.job.$id");
    $redis->multi;

    foreach my $key ( keys %$merge ) {

        croak qq{Invalid note key '$key'; must not contain '.', '[', or ']'}
          if $key =~ m/[\[\].]/;

        if ( defined $merge->{$key} ) {
            $redis->hset( "minion.job.$id.notes", $key,
                to_json( $merge->{$key} ) );
        }
        else {
            $redis->hdel( "minion.job.$id.notes", $key );
        }
    }

    $redis->exec;
    return !!1;
}

sub receive {
    my ( $self, $id ) = @_;
    my $redis = $self->redis->db;
    my $items = $redis->lrange( "minion.worker.$id.inbox", 0, -1 );
    $redis->watch("minion.worker.$id.inbox");
    $redis->multi;
    $redis->del("minion.worker.$id.inbox");
    $redis->exec;
    return [ map { from_json($_) } @$items ];
}

sub register_worker {
    my ( $self, $id, $options ) = ( shift, shift, shift || {} );

    $id //= $self->redis->db->incr('minion.last_worker_id');

    my $now = time;

    my $redis = $self->redis->db;
    $redis->multi;
    $redis->hmset(
        "minion.worker.$id",
        id     => $id,
        status => to_json( $options->{status} // {} ),
    );
    $redis->hsetnx( "minion.worker.$id", host => $self->{host} //= hostname );
    $redis->hsetnx( "minion.worker.$id", pid  => $$ );
    $redis->hsetnx( "minion.worker.$id", started => $now );
    $redis->zadd( 'minion.worker_notified', $now => $id );
    $redis->sadd( 'minion.workers', $id );
    $redis->exec;

    return $id;
}

sub remove_job {
    my ( $self, $id ) = @_;

    my $redis = $self->redis->db;
    my ( $queue, $state, $task, $worker ) =
      @{ $redis->hmget( "minion.job.$id", qw(queue state task worker) ) };
    return !!0
      unless defined $state
      and ($state eq 'inactive'
        or $state eq 'failed'
        or $state eq 'finished' );

    $redis->watch("minion.job.$id");
    $redis->multi;

    _delete_job( $redis, $id, $queue, $state, $task, $worker );
    $redis->exec;

    return 1;
}

sub repair {
    my $self = shift;

    # Workers without heartbeat
    my $redis  = $self->redis->db;
    my $minion = $self->minion;
    $redis->watch('minion.worker_notified');
    my $missing = $redis->zrangebyscore( 'minion.worker_notified',
        '-inf', '(' . ( time - $minion->missing_after ) );
    _delete_worker( $redis, $_ ) for @$missing;

    # Jobs with missing worker (can be retried)
    $redis->watch('minion.jobs_missing_worker');
    $redis->multi;

    $redis->sinter( 'minion.job_state.active', 'minion.jobs_missing_worker' );
    $redis->del('minion.jobs_missing_worker');
    my $orphaned_jobs = $redis->exec;

    # Duct tape to ensure we get a flat list of job IDs
    my @flattened_jobs = _flatten(@$orphaned_jobs);

    foreach my $id (@flattened_jobs) {
        my ( $queue, $retries ) =
          @{ $redis->hmget( "minion.job.$id", qw(queue retries) ) };

        if ( !$queue || $queue ne "minion_foreground" ) {
            $self->fail_job( $id, $retries, 'Worker went away' );
        }
    }

    # Old jobs with no unresolved dependencies
    my $old_jobs = $redis->zrangebyscore( 'minion.job_finished',
        '-inf', '(' . ( time - $minion->remove_after ) );
    foreach my $id (@$old_jobs) {
        my ( $queue, $state, $task, $worker ) =
          @{ $redis->hmget( "minion.job.$id", qw(queue state task worker) ) };
        next
          if @{
            $redis->sdiff( "minion.job.$id.children",
                'minion.job_state.finished' )
          };
        $redis->watch( "minion.job.$id", "minion.job.$id.children" );
        $redis->multi;
        _delete_job( $redis, $id, $queue, $state, $task, $worker );
        $redis->exec;
    }
}

sub reset {
    my ($self) = @_;
    my $redis = $self->redis->db;
    $redis->watch( 'minion.jobs', 'minion.workers' );
    my $keys = $redis->keys('minion.*');
    $redis->multi;
    $redis->del(@$keys) if @$keys;
    $redis->exec;
}

sub retry_job {
    my ( $self, $id, $retries, $options ) =
      ( shift, shift, shift, shift || {} );

    my $now = time;
    my %set;
    $set{attempts} = $options->{attempts} if defined $options->{attempts};
    $set{delayed}  = my $delayed = $now + ( $options->{delay} // 0 );
    $set{priority} = $options->{priority} if defined $options->{priority};
    $set{retried}  = $now;

    my $redis = $self->redis->db;
    $redis->watch("minion.job.$id");
    my ( $curr_queue, $curr_priority, $curr_retries, $curr_state, $task ) = @{
        $self->redis->db->hmget( "minion.job.$id",
            qw(queue priority retries state task) )
    };
    return !!0 unless defined $curr_retries and $curr_retries == $retries;

    $redis->multi;
    $redis->hmset( "minion.job.$id", %set );
    $redis->hincrby( "minion.job.$id", retries => 1 );

    my $alphaid = sprintf '%012d', $id;
    if ( defined $options->{queue} ) {
        $redis->hset( "minion.job.$id", queue => $options->{queue} );
        $redis->srem( "minion.job_queue.$curr_queue", $id );
        $redis->sadd( "minion.job_queue.$options->{queue}", $id );
        $redis->zrem( "minion.inactive_job_queue.$curr_queue", $alphaid );
    }

    $redis->hset( "minion.job.$id", state => 'inactive' );
    $redis->srem( "minion.job_state.$curr_state", $id );
    $redis->sadd( 'minion.job_state.inactive',               $id );
    $redis->sadd( 'minion.job_state.inactive,active,failed', $id );

    my $priority = $options->{priority} // $curr_priority;
    my $queue    = $options->{queue}    // $curr_queue;
    $redis->zadd( "minion.inactive_job_queue.$queue",
        ( 0 - $priority ) => $alphaid );
    $redis->zadd( "minion.inactive_job_task.$task", 0        => $alphaid );
    $redis->zadd( 'minion.inactive_job_delayed',    $delayed => $id );

    $redis->exec;

    $self->_notify_job if $delayed <= $now;

    return 1;
}

sub stats {
    my $self = shift;

    my %stats;
    $stats{inactive_jobs} =
      $self->redis->db->scard('minion.job_state.inactive');
    $stats{active_jobs} = $self->redis->db->scard('minion.job_state.active');
    $stats{failed_jobs} = $self->redis->db->scard('minion.job_state.failed');
    $stats{finished_jobs} =
      $self->redis->db->scard('minion.job_state.finished');
    $stats{delayed_jobs} =
      $self->redis->db->zcount( 'minion.inactive_job_delayed', time, '+inf' );
    $stats{active_workers} = 0;

    my $locks = 0;
    my $keys  = $self->redis->db->keys('minion.lock.*');

    foreach my $name (@$keys) {
        $locks += $self->redis->db->zcount( $name, time, '+inf' );
    }

    $stats{active_locks} = $locks;

    foreach my $id ( @{ $self->redis->db->smembers('minion.workers') } ) {
        $stats{active_workers}++
          if @{
            $self->redis->db->sinter( 'minion.job_state.active',
                "minion.worker.$id.jobs" )
          };
    }
    $stats{enqueued_jobs} = $self->redis->db->get('minion.last_job_id') // 0;
    $stats{inactive_workers} =
      $self->redis->db->scard('minion.workers') - $stats{active_workers};

    $stats{uptime} =
      $self->redis->db->info_structured('server')->{uptime_in_seconds};

    return \%stats;
}

sub unlock {
    my ( $self, $name ) = @_;
    my $redis = $self->redis->db;
    $redis->multi;
    $redis->zremrangebyscore( "minion.lock.$name", '-inf', '(' . time );
    $redis->zremrangebyrank( "minion.lock.$name", 0, 0 );
    my $res = $redis->exec;
    return !!$res->[1];
}

sub unregister_worker {
    my ( $self, $id ) = @_;
    my $redis = $self->redis->db;
    _delete_worker( $redis, $id );
}

sub _flatten {    # no prototype for this one to avoid warnings
    return map { ref eq 'ARRAY' ? _flatten(@$_) : $_ } @_;
}

sub _delete_job {
    my ( $redis, $id, $queue, $state, $task, $worker ) = @_;
    $redis->del(
        "minion.job.$id",         "minion.job.$id.notes",
        "minion.job.$id.parents", "minion.job.$id.children"
    );
    $redis->srem( "minion.job_queue.$queue",                 $id );
    $redis->srem( "minion.job_state.$state",                 $id );
    $redis->srem( "minion.job_task.$task",                   $id );
    $redis->srem( 'minion.job_state.inactive,active,failed', $id );
    $redis->srem( 'minion.jobs',                             $id );
    my $alphaid = sprintf '%012d', $id;
    $redis->zrem( "minion.inactive_job_queue.$queue", $alphaid );
    $redis->zrem( "minion.inactive_job_task.$task",   $alphaid );
    $redis->zrem( 'minion.inactive_job_delayed',      $id );
    $redis->zrem( 'minion.job_finished',              $id );
    $redis->srem( "minion.worker.$worker.jobs", $id ) if defined $worker;
}

sub _delete_worker {
    my ( $redis, $id ) = @_;
    $redis->multi;
    $redis->sunionstore( 'minion.jobs_missing_worker',
        'minion.jobs_missing_worker', "minion.worker.$id.jobs" );
    $redis->del( "minion.worker.$id", "minion.worker.$id.inbox",
        "minion.worker.$id.jobs" );
    $redis->srem( 'minion.workers', $id );
    $redis->zrem( 'minion.worker_notified', $id );
    $redis->exec;
}

sub _notify_job { shift->redis->pubsub->notify( 'minion.job', '' ) }

sub _try {
    my ( $self, $id, $options ) = @_;

    my $queues = $options->{queues} || ['default'];
    my $tasks  = [ keys %{ $self->minion->tasks } ];

    my $job;
    my $redis_job = $self->redis->db;
    my $now       = time;
    if ( defined $options->{id} ) {

        # ensure job isn't taken by someone else
        $redis_job->watch("minion.job.$options->{id}");
        $redis_job->multi;
        $redis_job->hmget( "minion.job.$options->{id}", qw(queue task) );
        my $result = $redis_job->exec;

        my ( $queue, $task ) = @{$result};

        if (    defined $task
            and exists $self->minion->tasks->{$task}
            and defined $queue
            and ( any { $_ eq $queue } @$queues ) )
        {
            $job = $self->_try_job( $options->{id}, $now );
        }
    }
    else {
        my $queue_hash = sha256_base64( encode 'UTF-8', join( ',', @$queues ) );
        my $queue_key  = "minion.temp.queues.$queue_hash";
        my $task_hash  = sha256_base64( encode 'UTF-8', join( ',', @$tasks ) );
        my $task_key   = "minion.temp.tasks.$task_hash";

        my $redis = $self->redis->db;
        $redis->multi;
        $redis->del($queue_key);
        $redis->zunionstore( $queue_key, scalar(@$queues),
            map { "minion.inactive_job_queue.$_" } @$queues )
          if @$queues;
        $redis->expire( $queue_key, 60 );
        $redis->del($task_key);
        $redis->zunionstore( $task_key, scalar(@$tasks),
            map { "minion.inactive_job_task.$_" } @$tasks )
          if @$tasks;
        $redis->expire( $task_key, 60 );

        my $priority_hash =
          sha256_base64( join '$', $queue_hash, $task_hash, $$, $now );
        my $priority_key = "minion.temp.inactive_jobs.$priority_hash";
        $redis->del($priority_key);
        $redis->zinterstore(
            $priority_key, 2, $queue_key, $task_key,
            WEIGHTS => 1,
            0
        );
        $redis->expire( $priority_key, 60 );
        $redis->exec;

        my $i = 0;
        while (
            my @check = @{
                $self->redis->db->zrangebyscore(
                    $priority_key,
                    '-inf', '+inf',
                    LIMIT => $i,
                    1
                )
            }
          )
        {
            my $check_id = 0 + $check[0];

            # ensure job isn't taken by someone else
            #$redis_job->watch("minion.job.$check_id");
            #$redis_job->multi;
            #print "ersdfsdf";
            $job = $self->_try_job( $check_id, $now );
            last if $job;
        }
        continue {
            #$redis_job->discard;
            $i++;
        }
    }

    return undef unless defined $job;

    $redis_job->multi;
    $redis_job->hmset(
        "minion.job.$job->{id}",
        started => time,
        state   => 'active',
        worker  => $id,
    );
    $redis_job->srem( 'minion.job_state.inactive', $job->{id} );
    $redis_job->sadd( 'minion.job_state.active', $job->{id} );
    $redis_job->srem( "minion.worker.$job->{worker}.jobs", $job->{id} )
      if defined $job->{worker};
    $redis_job->sadd( "minion.worker.$id.jobs", $job->{id} );
    my $alphaid = sprintf '%012d', $job->{id};
    $redis_job->zrem( "minion.inactive_job_queue.$job->{queue}", $alphaid );
    $redis_job->zrem( "minion.inactive_job_task.$job->{task}",   $alphaid );
    $redis_job->zrem( 'minion.inactive_job_delayed',             $job->{id} );
    $redis_job->exec;

    return {
        id      => $job->{id},
        args    => from_json( $job->{args} // 'null' ),
        retries => $job->{retries},
        task    => $job->{task},
    };
}

sub _try_job {
    my ( $self, $id, $now ) = @_;
    my ( $state, $delayed ) =
      @{ $self->redis->db->hmget( "minion.job.$id", qw(state delayed) ) };
    return undef
      unless defined $state
      and $state eq 'inactive'
      and defined $delayed
      and $delayed <= $now;
    my $pending = @{
        $self->redis->db->sinter( "minion.job.$id.parents",
            'minion.job_state.inactive,active,failed' )
    };
    return undef if $pending;
    my %job;
    @job{qw(id args queue retries task worker)} = @{
        $self->redis->db->hmget( "minion.job.$id",
            qw(id args queue retries task worker) )
    };
    return \%job;
}

sub _update {
    my ( $self, $fail, $id, $retries, $result ) = @_;

    my $state = $fail ? 'failed' : 'finished';
    my $redis = $self->redis->db;

    my ( $attempts, $curr_retries, $curr_state ) =
      @{ $redis->hmget( "minion.job.$id", qw(attempts retries state) ) };

    return undef
      unless defined $curr_retries
      and $curr_retries == $retries
      and defined $curr_state
      and $curr_state eq 'active';

    $redis->watch("minion.job.$id");
    $redis->multi;
    my $now = time;
    $redis->hmset(
        "minion.job.$id",
        finished => $now,
        result   => to_json($result),
        state    => $state,
    );
    $redis->srem( 'minion.job_state.active',                 $id );
    $redis->srem( 'minion.job_state.inactive,active,failed', $id )
      unless $fail;
    $redis->sadd( "minion.job_state.$state", $id );
    $redis->zadd( 'minion.job_finished', $now => $id ) unless $fail;
    $redis->exec;

    return 1 if !$fail || $attempts == 1;
    return 1 if $retries >= ( $attempts - 1 );
    my $delay = $self->minion->backoff->($retries);
    return $self->retry_job( $id, $retries, { delay => $delay } );
}

1;

=head1 NAME

Minion::Backend::Redis - Redis backend for Minion job queue

=head1 SYNOPSIS

  use Minion::Backend::Redis;
  my $backend = Minion::Backend::Redis->new('redis://127.0.0.1:6379/5');

  # Minion
  use Minion;
  my $minion = Minion->new(Redis => 'redis://127.0.0.1:6379');

  # Mojolicious (via Mojolicious::Plugin::Minion)
  $self->plugin(Minion => { Redis => 'redis://127.0.0.1:6379/2' });

  # Mojolicious::Lite (via Mojolicious::Plugin::Minion)
  plugin Minion => { Redis => 'redis://x:s3cret@127.0.0.1:6379' };

=head1 DESCRIPTION

L<Minion::Backend::Redis> is a backend for L<Minion> based on L<Mojo::Redis>.
Note that L<Redis Server|https://redis.io/download> version C<2.8.0> or newer
is required to use this backend.

=head1 CAUTION

This is a slightly hackish modification of the original code by L<Dan Book|https://github.com/Grinnz/Minion-Backend-Redis> to use L<Mojo::Redis> instead of L<Mojo::Redis2>.

Due to the original code being written against an older Minion version, "history" is currently unimplemented.

=head1 PERFORMANCE

You can run examples/minion_bench.pl to get some performance metrics.  

  Clean start with 10000 jobs
  Enqueued 10000 jobs in 52.6373450756073 seconds (189.979/s)
  4 workers finished 1000 jobs each in 76.6429250240326 seconds (52.190/s)
  4 workers finished 1000 jobs each in 64.2053661346436 seconds (62.300/s)
  Requesting job info 100 times
  Received job info 100 times in 0.783659934997559 seconds (127.606/s)
  Requesting stats 100 times
  Received stats 100 times in 0.595925092697144 seconds (167.806/s)
  Repairing 100 times
  Repaired 100 times in 0.28698992729187 seconds (348.444/s)
  Acquiring locks 1000 times
  Acquired locks 1000 times in 2.0602331161499 seconds (485.382/s)
  Releasing locks 1000 times
  Releasing locks 1000 times in 1.19675707817078 seconds (835.591/s)

=head1 ATTRIBUTES

L<Minion::Backend::Redis> inherits all attributes from L<Minion::Backend> and
implements the following new ones.

=head2 redis

  my $redis = $backend->redis;
  $backend  = $backend->redis(Mojo::Redis->new);

L<Mojo::Redis> object used to store all data.

=head1 METHODS

L<Minion::Backend::Redis> inherits all methods from L<Minion::Backend> and
implements the following new ones.

=head2 new

  my $backend = Minion::Backend::Redis->new;
  my $backend = Minion::Backend::Redis->new('redis://x:s3cret@localhost:6379/5');

Construct a new L<Minion::Backend::Redis> object.

=head2 broadcast

  my $bool = $backend->broadcast('some_command');
  my $bool = $backend->broadcast('some_command', [@args]);
  my $bool = $backend->broadcast('some_command', [@args], [$id1, $id2, $id3]);

Broadcast remote control command to one or more workers.

=head2 dequeue

  my $job_info = $backend->dequeue($worker_id, 0.5);
  my $job_info = $backend->dequeue($worker_id, 0.5, {queues => ['important']});

Wait a given amount of time in seconds for a job, dequeue it and transition
from C<inactive> to C<active> state, or return C<undef> if queues were empty.

These options are currently available:

=over 2

=item id

  id => '10023'

Dequeue a specific job.

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

=item attempts

  attempts => 25

Number of times performing this job will be attempted, with a delay based on
L<Minion/"backoff"> after the first attempt, defaults to C<1>.

=item delay

  delay => 10

Delay job for this many seconds (from now).

=item notes

  notes => {foo => 'bar', baz => [1, 2, 3]}

Hash reference with arbitrary metadata for this job.

=item parents

  parents => [$id1, $id2, $id3]

One or more existing jobs this job depends on, and that need to have
transitioned to the state C<finished> before it can be processed.

=item priority

  priority => 5

Job priority, defaults to C<0>. Jobs with a higher priority get performed first.

=item queue

  queue => 'important'

Queue to put job in, defaults to C<default>.

=back

=head2 fail_job

  my $bool = $backend->fail_job($job_id, $retries);
  my $bool = $backend->fail_job($job_id, $retries, 'Something went wrong!');
  my $bool = $backend->fail_job(
    $job_id, $retries, {msg => 'Something went wrong!'});

Transition from C<active> to C<failed> state, and if there are attempts
remaining, transition back to C<inactive> with an exponentially increasing
delay based on L<Minion/"backoff">.

=head2 finish_job

  my $bool = $backend->finish_job($job_id, $retries);
  my $bool = $backend->finish_job($job_id, $retries, 'All went well!');
  my $bool = $backend->finish_job($job_id, $retries, {msg => 'All went well!'});

Transition from C<active> to C<finished> state.

=head2 history

  my $history = $backend->history;

Get history information for job queue. Unimplemented for now.

These fields are currently available:

=over 2

=item daily

  daily => [{epoch => 12345, finished_jobs => 95, failed_jobs => 2}, ...]

Hourly counts for processed jobs from the past day.

=back

=head2 list_jobs

  my $results = $backend->list_jobs($offset, $limit);
  my $results = $backend->list_jobs($offset, $limit, {state => 'inactive'});

Returns the information about jobs in batches.

  # Check job state
  my $results = $backend->list_jobs(0, 1, {ids => [$job_id]});
  my $state = $results->{jobs}[0]{state};

  # Get job result
  my $results = $backend->list_jobs(0, 1, {ids => [$job_id]});
  my $result = $results->{jobs}[0]{result};

These options are currently available:

=over 2

=item ids

  ids => ['23', '24']

List only jobs with these ids.

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
amount of time in seconds.

These options are currently available:

=over 2

=item limit

  limit => 20

Number of shared locks with the same name that can be active at the same time,
defaults to C<1>.

=back

=head2 note

  my $bool = $backend->note($job_id, foo => 'bar');

Change a metadata field for a job.

=head2 receive

  my $commands = $backend->receive($worker_id);

Receive remote control commands for worker.

=head2 register_worker

  my $worker_id = $backend->register_worker;
  my $worker_id = $backend->register_worker($worker_id);
  my $worker_id = $backend->register_worker(
    $worker_id, {status => {queues => ['default', 'important']}});

Register worker or send heartbeat to show that this worker is still alive.

These options are currently available:

=over 2

=item status

  status => {queues => ['default', 'important']}

Hash reference with whatever status information the worker would like to share.

=back

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

Transition job back to C<inactive> state, already C<inactive> jobs may also be
retried to change options.

These options are currently available:

=over 2

=item attempts

  attempts => 25

Number of times performing this job will be attempted.

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

These fields are currently available:

=over 2

=item active_jobs

  active_jobs => 100

Number of jobs in C<active> state.

=item active_workers

  active_workers => 100

Number of workers that are currently processing a job.

=item delayed_jobs

  delayed_jobs => 100

Number of jobs in C<inactive> state that are scheduled to run at specific time
in the future. Note that this field is EXPERIMENTAL and might change without
warning!

=item enqueued_jobs

  enqueued_jobs => 100000

Rough estimate of how many jobs have ever been enqueued. Note that this field is
EXPERIMENTAL and might change without warning!

=item failed_jobs

  failed_jobs => 100

Number of jobs in C<failed> state.

=item finished_jobs

  finished_jobs => 100

Number of jobs in C<finished> state.

=item inactive_jobs

  inactive_jobs => 100

Number of jobs in C<inactive> state.

=item inactive_workers

  inactive_workers => 100

Number of workers that are currently not processing a job.

=item uptime

  uptime => 1000

Uptime in seconds.

=back

=head2 unlock

  my $bool = $backend->unlock('foo');

Release a named lock.

=head2 unregister_worker

  $backend->unregister_worker($worker_id);

Unregister worker.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Minion>, L<Mojo::Redis>
