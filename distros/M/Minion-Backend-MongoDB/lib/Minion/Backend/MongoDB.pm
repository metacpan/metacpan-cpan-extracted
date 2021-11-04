package Minion::Backend::MongoDB;
$Minion::Backend::MongoDB::VERSION = '1.12';
# ABSTRACT: MongoDB backend for Minion

use 5.016;    # Minion requires this so we require this.

use Mojo::Base 'Minion::Backend';

use boolean;
use BSON::OID;
use BSON::Types qw(:all);
use Mojo::URL;
use MongoDB;
use Sys::Hostname qw(hostname);
use Tie::IxHash;
use Time::HiRes qw(time);
use Time::Moment;

has 'dbclient';
has 'mongodb';
has jobs          => sub { $_[0]->mongodb->coll( $_[0]->prefix . '.jobs' ) };
has notifications =>
  sub { $_[0]->mongodb->coll( $_[0]->prefix . '.notifications' ) };
has prefix  => 'minion';
has workers => sub { $_[0]->mongodb->coll( $_[0]->prefix . '.workers' ) };
has locks   => sub { $_[0]->mongodb->coll( $_[0]->prefix . '.locks' ) };
has admin   => sub { $_[0]->dbclient->db('admin') };

# Friday 31 December 9999 23:59:59
has never => sub { Time::Moment->from_epoch(253402300799) };

sub broadcast {
    my ( $s, $command, $args, $ids ) =
      ( shift, shift, shift || [], shift || [] );

    my $match = {};
    my @ids   = map $s->_oid($_), @$ids;
    $match->{_id} = { '$in' => \@ids } if ( scalar(@ids) );
    my $res = $s->workers->update_many( $match,
        { '$push' => { inbox => [ $command, @$args ] } } );

    return !!$res->matched_count;
}

sub dequeue {
    my ( $self, $id, $wait, $options ) = @_;

    if ( ( my $job = $self->_try( $id, $options ) ) ) { return $job }
    $self->_await($wait);

    return $self->_try( $id, $options );
}

sub enqueue {
    my ( $self, $task, $args, $options ) =
      ( shift, shift, shift || [], shift || {} );

    my $id;

    if ( my $seq = $options->{sequence} ) {
        my $prev = $self->jobs->find_one( { sequence => $seq, next => undef },
            { _id => 1 } );
        unshift @{ $options->{parents} }, $prev->{_id} if $prev;
        $id = $self->_enqueue( $task, $args, $options );
        $self->jobs->update_one( { _id => $prev->{_id} },
            { '$set' => { next => $id } } );
    }
    else {
        $id = $self->_enqueue( $task, $args, $options );
    }

    $self->notifications->insert_one( { c => 'created' } );
    return $id->hex;
}

sub fail_job { shift->_update( 1, @_ ) }

sub finish_job { shift->_update( 0, @_ ) }

sub history {
    my $self = shift;

    my $dt_stop = Time::Moment->now_utc;

    my @dt_set   = reverse( map $dt_stop->minus_hours($_), ( 0 .. 23 ) );
    my $dt_start = $dt_set[0];
    my %acc      = (
        map {
            $_->strftime('%Y%j%H') => {
                epoch         => $_->epoch(),
                failed_jobs   => 0,
                finished_jobs => 0
            }
        } @dt_set
    );

    my $match = { '$match' => { finished => { '$gt' => $dt_start } } };
    my $group = {
        '$group' => {
            '_id' => {
                hour => { '$hour'      => { date => '$finished' } },
                day  => { '$dayOfYear' => { date => '$finished' } },
                year => { '$year'      => { date => '$finished' } }
            },
            finished_jobs => {
                '$sum' => {
                    '$cond' => {
                        if   => { '$eq' => [ '$state', 'finished' ] },
                        then => 1,
                        else => 0
                    }
                }
            },
            failed_jobs => {
                '$sum' => {
                    '$cond' => {
                        if   => { '$eq' => [ '$state', 'failed' ] },
                        then => 1,
                        else => 0
                    }
                }
            }
        }
    };

    my $cursor = $self->jobs->aggregate( [ $match, $group ] );

    while ( my $doc = $cursor->next ) {
        my $id = $doc->{_id};
        my $key =
          sprintf( "%04d%03d%02d", $id->{year}, $id->{day}, $id->{hour} );
        $acc{$key}->{$_} += $doc->{$_} for (qw(finished_jobs failed_jobs));
    }
    return { daily => [ @acc{ ( sort keys(%acc) ) } ] };
}

sub list_jobs {
    my ( $self, $lskip, $llimit, $options ) = @_;

    my $imatch = {};
    $options->{'_ids'} = [ map( $self->_oid($_), @{ $options->{ids} } ) ]
      if $options->{ids};
    foreach (qw(_id state task queue sequence)) {
        $imatch->{$_} = { '$in' => $options->{ $_ . 's' } }
          if $options->{ $_ . 's' };
    }
    $imatch->{_id} = { '$lt' => $options->{before} }
      if ( exists $options->{before} );
    if ( $options->{notes} ) {
        foreach ( @{ $options->{notes} } ) {
            $imatch->{"notes.$_"} = { '$exists' => 1 };
        }
    }
    $imatch->{'$or'} = [
        { state   => { '$ne' => 'inactive' } },
        { expires => { '$gt' => Time::Moment->now } }
    ];

    my $match  = { '$match' => $imatch };
    my $lookup = {
        '$lookup' => {
            from         => $self->prefix . '.jobs',
            localField   => '_id',
            foreignField => 'parents',
            as           => 'children'
        }
    };

# (select id from minion_jobs where sequence = j.sequence and next = j.id) as previous,
    my $l_previous = {
        '$lookup' => {
            from     => $self->prefix . '.jobs',
            let      => { sequence => '$sequence', next => '$_id' },
            pipeline => [
                {
                    '$match' => {
                        '$expr' => {
                            '$and' => [
                                { '$eq' => [ '$sequence', '$$sequence' ] },
                                { '$eq' => [ '$next',     '$$next' ] },
                            ]
                        }
                    }
                },
                { '$project' => { _id => 1 } },
            ],
            as => 'previous'
        }
    };
    my $u_previous = {
        '$unwind' => {
            path                       => '$previous',
            preserveNullAndEmptyArrays => true
        }
    };
    my $skip = { '$skip' => 0 + $lskip },
      my $limit = { '$limit' => 0 + $llimit },
      my $sort = { '$sort' => { _id => -1 } };
    my $iproject = {};
    foreach (
        qw(_id args attempts children notes priority queue result
        retries state task worker sequence next previous expires lax)
      )
    {
        $iproject->{$_} = 1;
    }
    foreach (qw(parents)) {
        $iproject->{$_} = { '$ifNull' => [ '$' . $_, [] ] };
    }
    foreach (qw(previous)) {
        $iproject->{$_} = { '$ifNull' => [ '$' . $_ . '._id', undef ] };
    }
    foreach (qw(created delayed finished retried started expires)) {
        $iproject->{$_} = {
            '$toLong' => {
                '$multiply' => [
                    {
                        '$convert' => { 'input' => '$' . $_, to => 'long' }
                    },
                    0.001
                ]
            }
        };
    }
    $iproject->{total} = { '$size' => '$children' };
    my $project = { '$project' => $iproject };

    my $aggregate = [
        $match, $lookup, $l_previous, $u_previous,
        $sort,  $skip,   $limit,      $project
    ];
    my $cursor = $self->jobs->aggregate($aggregate);
    my $total  = $self->jobs->count_documents($imatch);

    my $jobs = [ map $self->_job_info($_), $cursor->all ];

    return _total( 'jobs', $jobs, $total );
}

sub list_locks {
    my ( $self, $offset, $limit, $options ) = @_;

    my %aggregate;

    my $imatch = {};
    $imatch->{expires} = { '$gt' => bson_time() };
    $imatch->{name} = { '$in' => $options->{'names'} } if $options->{'names'};

    $aggregate{match}  = { '$match'  => $imatch };
    $aggregate{unwind} = { '$unwind' => '$expires' };
    $aggregate{skip}   = { '$skip'   => $offset // 0 },
      $aggregate{limit} = { '$limit' => $limit }
      if ($limit);

    my $iproject = {};
    foreach (qw(expires)) {
        $iproject->{$_} = {
            '$toLong' => {
                '$multiply' => [
                    {
                        '$convert' => { 'input' => '$' . $_, to => 'long' }
                    },
                    0.001
                ]
            }
        };
    }
    $iproject->{_id}  = 0;
    $iproject->{name} = 1;

    $aggregate{project} = { '$project' => $iproject };
    $aggregate{sort}    = { '$sort'    => { expires => -1 } };

    my @aggregate = grep defined,
      map { $aggregate{$_} } qw(match unwind sort skip limit project);

    my $cursor = $self->locks->aggregate( \@aggregate );
    my $total  = $self->_locks_count($imatch);

    my $locks = [ $cursor->all ];

    return _total( 'locks', $locks, $total );
}

sub list_workers {
    my ( $self, $offset, $limit, $options ) = @_;

    my $match = {};
    $options->{'_ids'} = [ map( $self->_oid($_), @{ $options->{ids} } ) ]
      if $options->{ids};
    foreach (qw(_id)) {
        $match->{$_} = { '$in' => $options->{ $_ . 's' } }
          if $options->{ $_ . 's' };
    }
    $match->{_id} = { '$lt' => $options->{before} }
      if ( exists $options->{before} );

    my $cursor = $self->workers->find($match);
    my $total  = scalar( $cursor->all );
    $cursor->reset;
    $cursor->sort( { _id => -1 } )->skip($offset)->limit($limit);
    my $workers = [ map { $self->_worker_info($_) } $cursor->all ];
    return _total( 'workers', $workers, $total );
}

sub lock {
    my ( $s, $name, $duration, $options ) =
      ( shift, shift, shift, shift // {} );
    return $s->_lock( $name, $duration, $options->{limit} || 1 );
}

sub minion {
    my $s      = shift;
    my $minion = shift;
    return $s->{minion} unless $minion;
    $s->{minion} = $minion;
    $s->_reconnect_db;
    return $s;
}

sub new {
    my ( $class, $url ) = ( shift, shift );
    my $client = MongoDB->connect( $url, @_ );
    my $db     = $client->db( $client->db_name );

    my $self = $class->SUPER::new( dbclient => $client, mongodb => $db );
    return $self;
}

sub note {
    my ( $self, $id, $merge ) = @_;
    return 0 if ( !keys %$merge );
    my $set   = {};
    my $unset = {};
    while ( my ( $k, $v ) = each %$merge ) {
        ( defined $v ? $set : $unset )->{"notes.$k"} = $v;
    }
    my @update = ( { _id => $self->_oid($id) } );
    my %set_unset;
    $set_unset{'$set'}   = $set   if ( keys %$set );
    $set_unset{'$unset'} = $unset if ( keys %$unset );
    push @update, \%set_unset;
    push @update,
      {
        upsert         => 0,
        returnDocument => 'after',
      };
    return $self->jobs->find_one_and_update(@update) ? 1 : 0;
}

sub purge {
    my ( $s, $opts ) = @_;

    # options keys: queues, states, older, tasks
    # defaults
    $opts->{older}       //= $s->minion->remove_after;
    $opts->{older_field} //= 'finished';

    my %match;
    $match{ $opts->{older_field} } =
      { '$lt' => Time::Moment->now->minus_seconds( $opts->{older} ) };
    foreach (qw/queue state task/) {
        $match{$_} = { '$in' => $opts->{ $_ . 's' } }
          if ( $opts->{ $_ . 's' } );
    }

    $s->jobs->delete_many( \%match );
}

sub receive {
    my ( $self, $id ) = @_;
    my $oldrec = $self->workers->find_one_and_update(
        { _id => $self->_oid($id), inbox => { '$exists' => 1, '$ne' => [] } },
        { '$set' => { inbox => [] } },
        {
            upsert         => 0,
            returnDocument => 'before',
        }
    );

    return $oldrec ? $oldrec->{inbox} // [] : [];
}

sub register_worker {
    my ( $self, $id, $options ) = @_;

    $self->_init_db;

    my $now = Time::Moment->now;

    return $id
      if $id
      && $self->workers->find_one_and_update(
        { _id => $self->_oid($id) },
        {
            '$set' => {
                notified => $now,
                status   => $options->{status} // {}
            }
        }
      );

    my $res = $self->workers->insert_one(
        {
            host     => hostname,
            pid      => $$,
            started  => $now,
            notified => $now,
            status   => $options->{status} // {},
            inbox    => [],
        }
    );

    return $res->inserted_id->hex;
}

sub remove_job {
    my ( $self, $id ) = @_;
    my $doc = {
        _id   => $self->_oid($id),
        state => { '$in' => [qw(failed finished inactive)] }
    };
    return !!$self->jobs->delete_one($doc)->deleted_count;
}

sub repair {
    my $self   = shift;
    my $minion = $self->minion;

    my $now = Time::Moment->now;

    # Workers without heartbeat
    $self->workers->delete_many(
        {
            notified => {
                '$lt' => $now->minus_seconds( $minion->missing_after )
            }
        }
    );

    my $jobs = $self->jobs;

    # Old jobs with no unresolved dependencies and expired jobs

# find: select 1 from minion_jobs where parents @> ARRAY[j.id] and state != 'finished'
    my $docs = $jobs->aggregate(
        [
            {
                '$match' => {
                    state    => 'finished',
                    finished => {
                        '$lte' => $now->minus_seconds( $minion->remove_after )
                    }
                }
            },
            {
                '$lookup' => {
                    from     => $self->prefix . '.jobs',
                    let      => { parent => '$_id' },
                    pipeline => [
                        {
                            '$match' => {
                                '$expr' => {
                                    '$and' => [
                                        { '$in' => [ '$$parent', '$parents' ] },
                                        { '$ne' => [ '$state',   'finished' ] },
                                    ],
                                }
                            },
                        },
                    ],
                    as => 'parents'
                }
            },
        ]
    );
    my @ids_to_delete;
    while ( my $doc = $docs->next ) {
        push @ids_to_delete, $doc->{_id}
          unless ( scalar( @{ $doc->{parents} } ) );
    }
    $jobs->delete_many( { _id => { '$in' => \@ids_to_delete } } );

    # or (expires <= now() and state = 'inactive')
    $jobs->delete_many(
        { expires => { '$lte' => $now }, state => 'inactive' } );

    # Jobs with missing worker (can be retried)
    my $cursor = $jobs->find(
        {
            state => 'active',
            queue => { '$ne' => 'minion_foreground' }
        }
    );
    while ( my $job = $cursor->next ) {
        $self->fail_job( @$job{qw(_id retries)}, 'Worker went away' )
          unless $self->workers->count_documents( { _id => $job->{worker} } );
    }

    # Jobs in queue without workers or not enough workers
    # (cannot be retried and requires admin attention)
    $jobs->update_many(
        {
            state   => 'inactive',
            delayed => {
                '$lt' => $now->minus_seconds( $minion->stuck_after )
            },
        },
        {
            '$set' =>
              { state => 'failed', result => 'Job appears stuck in queue' }
        }
    );

}

sub reset {
    my ( $s, $options ) = ( shift, shift // {} );
    if ( $options->{all} ) {
        $_->drop for $s->workers, $s->jobs, $s->locks;
    }
    elsif ( $options->{locks} ) {
        $_->drop for $s->{locks};
    }
    else {
        warn "Starting to v10.0 you must explicit what you want to reset";
    }
    $s->_init_db;
}

sub retry_job {
    my ( $self, $id, $retries, $options ) =
      ( shift, shift, shift, shift || {} );
    $options->{delay} //= 0;

    my $dt_now = Time::Moment->now();

    my $query  = { _id => $self->_oid($id), retries => $retries };
    my $update = {
        '$inc' => { retries => 1 },
        '$set' => {
            retried => $dt_now,
            state   => 'inactive',
            delayed => $dt_now->plus_seconds( $options->{delay} || 0 ),
        },
    };

    $update->{'$set'}->{expires} = $dt_now->plus_seconds( $options->{expire} )
      if exists $options->{expire};

    foreach (qw(attempts parents priority queue lax)) {
        $update->{'$set'}->{$_} = $options->{$_} if ( defined $options->{$_} );
    }

    my $res = $self->jobs->update_one( $query, $update );
    $self->notifications->insert_one( { c => 'update_retries' } );
    return !!$res->matched_count;
}

sub stats {
    my $self = shift;

    my $jobs   = $self->jobs;
    my $active = @{
        $self->mongodb->run_command(
            [
                distinct => $jobs->name,
                key      => 'worker',
                query    => { state => 'active' }
            ]
        )->{values}
    };
    my $all = $self->workers->count_documents( {} );
    my $stats =
      { active_workers => $active, inactive_workers => $all - $active };
    $stats->{inactive_jobs} = $jobs->count_documents(
        {
            state   => 'inactive',
            expires => { '$gt' => Time::Moment->now }
        }
    );
    $stats->{"${_}_jobs"} = $jobs->count_documents( { state => $_ } )
      for qw(active failed finished);
    $stats->{active_locks} = $self->list_locks->{total};
    $stats->{delayed_jobs} = $self->jobs->count_documents(
        {
            state   => 'inactive',
            delayed => { '$gt' => bson_time }
        }
    );

   # I don't know if this value is correct as calculated. PG use the incremental
   # sequence id
    $stats->{enqueued_jobs} += $stats->{"${_}_jobs"}
      for qw(active failed finished inactive);
    eval {
        $stats->{uptime} =
          $self->admin->run_command( Tie::IxHash->new( 'serverStatus' => 1 ) )
          ->{uptime};
    };

    # User doesn't have admin authorization. Server uptime missing
    $stats->{uptime} = -1 if ($@);
    return $stats;
}

sub unlock {
    my ( $s, $name ) = @_;

    # remove the first (more proximum to expiration) lock
    my $doc = $s->locks->find_one_and_update( { name => $name },
        { '$pop' => { expires => -1 } } );

    # delete lock record if expires is empty
    $s->locks->delete_one( { name => $name, expires => { '$size' => 0 } } )
      if ($doc);

    return defined $doc;
}

sub unregister_worker {
    $_[0]->workers->delete_one( { _id => $_[0]->_oid( $_[1] ) } );
}

sub worker_info {
    $_[0]->_worker_info( $_[0]->workers->find_one( { _id => $_[1] } ) );
}

sub _await {
    my $s    = shift;
    my $wait = shift || 0.5;

    my $last   = BSON::OID->new;
    my $cursor = $s->notifications->find(
        {
            _id => { '$gt' => $last },
        }
    )->tailable_await(1)->max_await_time_ms( $wait * 1000 );
    $cursor->has_next;
}

sub _enqueue {
    my ( $self, $task, $args, $options ) = @_;
    @{ $options->{parents} } = map $self->_oid($_), @{ $options->{parents} }
      if ( exists $options->{parents} );

    my $now = Time::Moment->now();
    my $doc = {
        args    => $args,
        created => $now,
        delayed => $options->{delay} ? $now->plus_seconds( $options->{delay} )
        : $now,
        priority => $options->{priority} // 0,
        state    => 'inactive',
        task     => $task,
        retries  => 0,
        attempts => $options->{attempts} // 1,
        notes    => $options->{notes}   || {},
        parents  => $options->{parents} || [],
        queue    => $options->{queue} // 'default',
        sequence => $options->{sequence},
        expires => $options->{expire} ? $now->plus_seconds( $options->{expire} )
        : $self->never,
        lax => $options->{lax} ? 1 : 0,
    };

    my $res = $self->jobs->insert_one($doc);
    my $id  = $res->inserted_id;
    return $id;
}

sub _init_db {
    my $s = shift;

    # indexes for jobs

    $s->jobs->indexes->create_one( Tie::IxHash->new( finished => 1 ) );

    # for _try main query
    $s->jobs->indexes->create_one(
        Tie::IxHash->new(
            state    => 1,
            priority => -1,
            _id      => 1,
            delayed  => 1,
            expires  => -1,
            task     => 1,
            queue    => 1
        )
    );
    $s->jobs->indexes->create_one(
        Tie::IxHash->new( sequence => 1, next => 1 ) );

    # indexes for locks
    $s->locks->indexes->create_one( Tie::IxHash->new( name => 1 ),
        { unique => 1 } );
    $s->locks->indexes->create_one( Tie::IxHash->new( expires => 1 ) );

    # Capped collection for notifications
    $s->_notifications;
}

sub _job_info {
    my $self = shift;

    return undef unless my $job = shift;

    $job->{id} = $job->{_id}->hex;
    $job->{retries} //= 0;
    $job->{children} = [ map $_->{_id}->hex, @{ $job->{children} } ];
    $job->{time}     = Time::Moment->now->epoch;    # server time

    return $job;
}

sub _lock {
    my ( $s, $name, $duration, $count ) = @_;

    my $dt_now = Time::Moment->now;
    my $dt_exp = $dt_now->plus_seconds($duration);

    my $match = { name => $name };

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
    my $del = $s->locks->update_many( {},
        { '$pull' => { expires => { '$lte' => $dt_now } } } );

    # delete lock record if expires is empty
    $s->locks->delete_one( { name => $name, expires => { '$size' => 0 } } )
      if ( $del->{modified_count} );

    return 1;
}

sub _locks_count {
    my $s     = shift;
    my $match = shift;

    my @aggregate = (
        {
            '$group' => {
                _id         => undef,
                locks_count => { '$sum' => { '$size' => '$expires' } }
            }
        },
        { '$project' => { _id => 0 } }
    );

    unshift @aggregate, { '$match' => $match } if $match;

    my $rec = $s->locks->aggregate( \@aggregate )->next;

    return $rec ? $rec->{locks_count} : 0;
}

sub _notifications {
    my $self = shift;

    # We can only await data if there's a document in the collection
    $self->{capped} ? return : $self->{capped}++;
    my $notifications = $self->notifications;
    return
      if grep { $_ eq $notifications->name } $self->mongodb->collection_names;

    $self->mongodb->run_command(
        [
            create => $notifications->name,
            capped => true,
            size   => 10240,
            max    => 128
        ]
    );
    $notifications->insert_one( {} );
}

sub _oid {
    return defined $_[1] ? BSON::OID->new( oid => pack( "H*", $_[1] ) ) : undef;
}

sub _reconnect_db {
    my $s = shift;
    $s->minion->on(
        worker => sub {
            $_[1]->on(
                dequeue => sub {
                    $_[1]->on(
                        spawn => sub {
                            $s->minion->backend->mongodb->client->reconnect();
                        }
                    );
                }
            );
        }
    );
}

sub _total {
    my ( $name, $res, $tot ) = @_;
    return { total => $tot, $name => $res };
}

sub _try {
    my ( $self, $id, $options ) = @_;

    my $now = Time::Moment->now;

    # find documents inactive
    my $match = Tie::IxHash->new(
        delayed => { '$lte' => $now },
        state   => 'inactive',
        task    => { '$in' => [ keys %{ $self->minion->tasks } ] },
        queue   => { '$in' => $options->{queues} // ['default'] },
        expires => { '$gt' => $now },
    );
    $match->Push( '_id' => $self->_oid( $options->{id} ) )
      if defined $options->{id};
    $match->Push( 'priority' => { '$gte' => $options->{min_priority} } )
      if exists $options->{min_priority};

    my $docs =
      $self->jobs->find( $match, { sort => [ 'priority', -1, '_id', 1 ] } );

    # find a document inactive with no problems with parents and set as active
    my $find = 0;
    my $doc_matched;
    my $job;

    my $make_job_active = [
        { _id => 'template', state => 'inactive' },
        {
            '$set' => {
                started => $now,
                state   => 'active',
                worker  => $self->_oid($id)
            }
        },
        {
            projection     => { args => 1, retries => 1, task => 1 },
            upsert         => 0,
            returnDocument => 'after',
        }
    ];
    while ( ( my $doc = $docs->next ) && !defined $job ) {
        $make_job_active->[0]->{_id} = $doc->{_id};

        # try if doc has no parent and is still inactive or not exist... where
        (
            # parents = '{}'
            !scalar @{ $doc->{parents} } ||

              # not exist ... where
              !$self->jobs->count_documents(
                {
                    '$and' => [
                        { _id => { '$in' => $doc->{parents} } }
                        ,    # (id = any parents) and
                        {
                            '$or' => [
                                { state => 'active' },
                                {
                                    '$and' => [
                                        { state => 'failed' },
                                        {
                                            _id => { '$exists' => !$doc->{lax} }
                                        }    # a bad way to say "not doc.lax"
                                    ]
                                },
                                {
                                    '$and' => [
                                        { state   => 'inactive' },
                                        { expires => { '$gt' => $now } },
                                    ]
                                },
                            ]
                        }
                    ]
                }
              )
        ) && ( $job = $self->jobs->find_one_and_update(@$make_job_active) );

    }
    return undef unless ( $job || $job->{_id} );
    $job->{id} = $job->{_id}->hex;
    return $job;
}

sub _update {
    my ( $self, $fail, $id, $retries, $result ) = @_;

    my $update = {
        finished => Time::Moment->now,
        state    => $fail ? 'failed'     : 'finished',
        result   => $fail ? $result . '' : $result,
    };
    my $query =
      { _id => $self->_oid($id), state => 'active', retries => $retries };
    my $doc = $self->jobs->find_one_and_update(
        $query,
        { '$set'         => $update },
        { returnDocument => 'after' }
    );

    return undef unless ( $doc->{attempts} );

    # return 1 if !$fail || (my $attempts = $doc->{attempts}) == 1;
    # return 1 if $retries >= ($attempts - 1);
    # my $delay = $self->minion->backoff->($retries);
    return $fail
      ? $self->auto_retry_job( $id, $retries, $doc->{attempts} )
      : 1;
}

sub _worker_info {
    my $self = shift;

    return undef unless my $worker = shift;

    # lookup jobs
    my $cursor =
      $self->jobs->find( { state => 'active', worker => $worker->{_id} } );

    return {
        host     => $worker->{host},
        id       => $worker->{_id}->hex,
        jobs     => [ map { $_->{_id}->hex } $cursor->all ],
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

=head1 NAME

Minion::Backend::MongoDB - MongoDB backend for Minion

=for html <p>
    <a href="https://github.com/avkhozov/Minion-Backend-MongoDB/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/avkhozov/Minion-Backend-MongoDB/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/avkhozov/Minion-Backend-MongoDB">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/avkhozov/Minion-Backend-MongoDB">
</p>

=head1 VERSION

version 1.12

=head1 SYNOPSIS

  use Minion::Backend::MongoDB;

  my $backend = Minion::Backend::MongoDB->new('mongodb://127.0.0.1:27017');

=head1 DESCRIPTION

This is a L<MongoDB> backend for L<Minion> derived from
L<Minion::Backend::Pg> and supports for all its features.
L<Mojolicious> 9.0 compatibility and synced with L<Minion::Backend::Pg> v.10.22
features.

=encoding UTF-8

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
  my $job_info = $backend->dequeue($worker_id, 0.5, {queues => ['important']});

Wait a given amount of time in seconds for a job, dequeue it and transition from C<inactive> to C<active> state, or
return C<undef> if queues were empty.

These options are currently available:

=over 2

=item id

  id => '10023'

Dequeue a specific job.

=item min_priority

  min_priority => 3

Do not dequeue jobs with a lower priority.

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

Number of times performing this job will be attempted, with a delay based on L<Minion/"backoff"> after the first
attempt, defaults to C<1>.

=item delay

  delay => 10

Delay job for this many seconds (from now), defaults to C<0>.

=item expire

  expire => 300

Job is valid for this many seconds (from now) before it expires. Note that this option is B<EXPERIMENTAL> and might
change without warning!

=item lax

  lax => 1

Existing jobs this job depends on may also have transitioned to the C<failed> state to allow for it to be processed,
defaults to C<false>. Note that this option is B<EXPERIMENTAL> and might change without warning!

=item notes

  notes => {foo => 'bar', baz => [1, 2, 3]}

Hash reference with arbitrary metadata for this job.

=item parents

  parents => [$id1, $id2, $id3]

One or more existing jobs this job depends on, and that need to have transitioned to the state C<finished> before it
can be processed.

=item priority

  priority => 5

Job priority, defaults to C<0>. Jobs with a higher priority get performed first. Priorities can be positive or negative,
but should be in the range between C<100> and C<-100>.

=item queue

  queue => 'important'

Queue to put job in, defaults to C<default>.

=item sequence

  sequence => 'host:mojolicious.org'

Sequence this job belongs to. The previous job from the sequence will be automatically added as a parent to continue the
sequence. Note that this option is B<EXPERIMENTAL> and might change without warning!

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

  # Get the total number of results (without limit)
  my $num = $backend->list_jobs(0, 100, {queues => ['important']})->{total};
  # Check job state
  my $results = $backend->list_jobs(0, 1, {ids => [$job_id]});
  my $state = $results->{jobs}[0]{state};
  # Get job result
  my $results = $backend->list_jobs(0, 1, {ids => [$job_id]});
  my $result = $results->{jobs}[0]{result};

These options are currently available:

=over 2

=item before

  before => 23

List only jobs before this id.

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

=item sequences

  sequences => ['host:localhost', 'host:mojolicious.org']

List only jobs from these sequences. Note that this option is B<EXPERIMENTAL> and might change without warning!

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

=item next

  next => 10024

Next job in sequence.

=item notes

  notes => {foo => 'bar', baz => [1, 2, 3]}

Hash reference with arbitrary metadata for this job.

=item previous

  previous => 10022

Previous job in sequence.

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

=item sequence

  sequence => 'host:mojolicious.org'

Sequence name.

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

=item before

  before => 23

List only workers before this id.

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

=head2 purge

  $backend->purge();
  $backend->purge({states => ['inactive'], older => 3600});

Purge all jobs created older than...

These options are currently available:

=over 2

=item older

  older => 3600

Value in seconds to purge jobs older than this value.

Default: $minion->remove_after

=item older_field

  older_field => 'created'

What date field to use to check if job is older than.

Default: 'finished'

=item queues

  queues => ['important', 'unimportant']

Purge only jobs in these queues.

=item states

  states => ['inactive', 'failed']

Purge only jobs in these states.

=item tasks

  tasks => ['task1', 'task2']

Purge only jobs for these tasks.

=item queues

  queues => ['q1', 'q2']

Purge only jobs for these queues.

=back

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

  $backend->reset({all => 1});

Reset job queue.

These options are currently available:

=over 2

=item all

  all => 1

Reset everything.

=item locks

  locks => 1

Reset only locks.

=back

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

=head2 _oid

  my $mongo_oid = $backend->_oid($hex_24length);

EXPERIMENTAL: Convert an 24-byte hexadecimal value into a C<BSON::OID> object.
Usually, it should be used only if you need to query the MongoDB directly

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

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/avkhozov/Minion-Backend-MongoDB/issues>
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/avkhozov/Minion-Backend-MongoDB/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Minion::Backend::MongoDB

=head1 SEE ALSO

L<Minion>, L<MongoDB>, L<Minion::Guide>, L<https://minion.pm>,
L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>, Andrey Khozov <avkhozov@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2021 by Emiliano Bruni, Andrey Khozov.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
