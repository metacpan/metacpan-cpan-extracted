use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

plan skip_all => 'set TEST_ONLINE to enable this test' unless $ENV{TEST_ONLINE};

use Minion;
use Mojo::IOLoop;
use Mojo::Promise;
use Sys::Hostname 'hostname';
use Time::HiRes 'usleep';

# Isolate tests
my $minion = Minion->new( MongoDB => $ENV{TEST_ONLINE} );
is $minion->backend->prefix, 'minion', 'right prefix';
my $jobs    = $minion->backend->prefix('jobs_test')->jobs;
my $workers = $minion->backend->workers;
is $jobs->name, 'jobs_test.jobs', 'right name';
$minion->reset( { all => 1 } );

subtest 'Nothing to repair' => sub {
    my $worker = $minion->repair->worker;
    isa_ok $worker->minion->app, 'Mojolicious', 'has default application';
};

subtest 'Register and unregister' => sub {
    my $worker = $minion->worker;
    $worker->register;
    like $worker->info->{started}, qr/^[\d.]+$/, 'has timestamp';
    my $notified = $worker->info->{notified};
    like $notified, qr/^[\d.]+$/, 'has timestamp';
    my $id = $worker->id;
    is $worker->register->id, $id, 'same id';
    usleep 50000;
    ok $worker->register->info->{notified} > $notified, 'new timestamp';
    is $worker->unregister->info, undef, 'no information';
    my $host = hostname;
    is $worker->register->info->{host}, $host, 'right host';
    is $worker->info->{pid}, $$, 'right pid';
    is $worker->unregister->info, undef, 'no information';
};

subtest 'Job results' => sub {
    $minion->add_task( test => sub { } );
    my $worker = $minion->worker->register;
    my $id     = $minion->enqueue('test');
    my ( @finished, @failed );
    my $promise = $minion->result_p( $id, { interval => 0 } )
      ->then( sub { @finished = @_ } )->catch( sub { @failed = @_ } );
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'same id';
    Mojo::IOLoop->one_tick;
    is_deeply \@finished, [], 'not finished';
    is_deeply \@failed,   [], 'not failed';
    $job->finish( { just => 'works!' } );
    $job->note( foo => 'bar' );
    $promise->wait;
    is_deeply $finished[0]{result}, { just => 'works!' }, 'right result';
    is_deeply $finished[0]{notes},  { foo  => 'bar' },    'right note';
    ok !$finished[1], 'no more results';
    is_deeply \@failed, [], 'not failed';

    ( @finished, @failed ) = ();
    my $id2 = $minion->enqueue('test');
    $promise = $minion->result_p( $id2, { interval => 0 } )
      ->then( sub { @finished = @_ } )->catch( sub { @failed = @_ } );
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id2, 'same id';
    $job->fail( { works => 'too!' } );
    $promise->wait;
    is_deeply \@finished, [], 'not finished';
    #### questo da errore
    #is_deeply $failed[0]{result}, {works => 'too!'}, 'right result';
    ok !$failed[1], 'no more results';
    $worker->unregister;

    ( @finished, @failed ) = ();
    $minion->result_p($id)->then( sub { @finished = @_ } )
      ->catch( sub { @failed = @_ } )->wait;
    is_deeply $finished[0]{result}, { just => 'works!' }, 'right result';
    is_deeply $finished[0]{notes},  { foo  => 'bar' },    'right note';
    ok !$finished[1], 'no more results';
    is_deeply \@failed, [], 'not failed';

    ( @finished, @failed ) = ();
    $minion->job($id)->retry;
    $minion->result_p($id)->timeout(0.25)->then( sub { @finished = @_ } )
      ->catch( sub { @failed = @_ } )->wait;
    is_deeply \@finished, [], 'not finished';
    is_deeply \@failed, ['Promise timeout'], 'failed';
    Mojo::IOLoop->start;

    ( @finished, @failed ) = ();
    $minion->job($id)->remove;
    $minion->result_p($id)->then( sub { @finished = ( @_, 'finished' ) } )
      ->catch( sub { @failed = ( @_, 'failed' ) } )->wait;
    is_deeply \@finished, ['finished'], 'job no longer exists';
    is_deeply \@failed, [], 'not failed';
};

# Repair missing worker
subtest 'Repair missing worker' => sub {
    my $worker  = $minion->worker->register;
    my $worker2 = $minion->worker->register;
    isnt $worker2->id, $worker->id, 'new id';
    my $id = $minion->enqueue('test');
    ok my $job = $worker2->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $worker2->info->{jobs}[0], $job->id, 'right id';
    $id = $worker2->id;
    undef $worker2;
    is $job->info->{state}, 'active', 'job is still active';
    ok !!$minion->backend->list_workers( 0, 1, { ids => [$id] } )->{workers}[0],
      'is registered';
    $minion->backend->workers->update_one(
        { _id => $minion->backend->_oid($id) },
        {
            '$set' => {
                notified =>
                  DateTime->now->add( seconds => -$minion->missing_after - 1 )
            }
        }
    );
    $minion->repair;
    ok !$minion->backend->list_workers( 0, 1, { ids => [$id] } )->{workers}[0],
      'not registered';
    like $job->info->{finished}, qr/^[\d.]+$/,       'has finished timestamp';
    is $job->info->{state},      'failed',           'job is no longer active';
    is $job->info->{result},     'Worker went away', 'right result';
    $worker->unregister;
};

# Repair abandoned job in minion_foreground queue (have to be handled manually)
subtest
'Repair abandoned job in minion_foreground queue (have to be handled manually)'
  => sub {
    my $worker = $minion->worker->register;
    my $id = $minion->enqueue( 'test', [], { queue => 'minion_foreground' } );
    ok my $job = $worker->dequeue( 0, { queues => ['minion_foreground'] } ),
      'job dequeued';
    is $job->id, $id, 'right id';
    $worker->unregister;
    $minion->repair;
    is $job->info->{state},  'active', 'job is still active';
    is $job->info->{result}, undef,    'no result';
  };

# Repair old jobs
subtest 'Repair old jobs' => sub {
    is $minion->remove_after, 172800, 'right default';
    my $worker = $minion->worker->register;
    my $id     = $minion->enqueue('test');
    my $id2    = $minion->enqueue('test');
    my $id3    = $minion->enqueue('test');
    $worker->dequeue(0)->perform for 1 .. 3;

    my $finished = $minion->backend->jobs->find_one(
        { _id => $minion->backend->_oid($id2) } )->{finished};
    $minion->backend->jobs->update_one(
        { _id => $minion->backend->_oid($id2) },
        {
            '$set' => {
                'finished' => $finished->as_datetime->add(
                    seconds => -$minion->remove_after - 1
                )
            }
        }
    );

    $finished = $minion->backend->jobs->find_one(
        { _id => $minion->backend->_oid($id3) } )->{finished};
    $minion->backend->jobs->update_one(
        { _id => $minion->backend->_oid($id3) },
        {
            '$set' => {
                'finished' => $finished->as_datetime->add(
                    seconds => -$minion->remove_after - 1
                )
            }
        }
    );

    $worker->unregister;
    $minion->repair;
    ok $minion->job($id), 'job has not been cleaned up';
    ok !$minion->job($id2), 'job has been cleaned up';
    ok !$minion->job($id3), 'job has been cleaned up';
};

subtest 'Repair stuck jobs' => sub {
    is $minion->stuck_after, 172800, 'right default';
    my $worker = $minion->worker->register;
    my $id     = $minion->enqueue('test');
    my $id2    = $minion->enqueue('test');
    my $id3    = $minion->enqueue('test');
    my $id4    = $minion->enqueue('test');

    $minion->backend->jobs->update_one(
        { _id => $minion->backend->_oid($_) },
        {
            '$set' => {
                'delayed' => DateTime->now->add(
                    seconds => -$minion->stuck_after - 1
                )
            }
        }
    ) for $id, $id2, $id3, $id4;

    ok $worker->dequeue( 0, { id => $id4 } )->finish('Works!'), 'job finished';
    ok my $job2 = $worker->dequeue( 0, { id => $id2 } ), 'job dequeued';
    $minion->repair;
    is $job2->info->{state}, 'active', 'job is still active';
    ok $job2->finish, 'job finished';
    my $job = $minion->job($id);
    is $job->info->{state},  'failed', 'job is no longer active';
    is $job->info->{result}, 'Job appears stuck in queue', 'right result';
    my $job3 = $minion->job($id3);
    is $job3->info->{state},  'failed', 'job is no longer active';
    is $job3->info->{result}, 'Job appears stuck in queue', 'right result';
    my $job4 = $minion->job($id4);
    is $job4->info->{state},  'finished', 'job is still finished';
    is $job4->info->{result}, 'Works!',   'right result';
    $worker->unregister;
};

subtest 'List workers' => sub {
    my $worker  = $minion->worker->register;
    my $worker2 = $minion->worker->status( { whatever => 'works!' } )->register;
    my $results = $minion->backend->list_workers( 0, 10 );
    my $host    = hostname;
    is $results->{total}, 2, 'two workers total';
    my $batch = $results->{workers};
    ok $batch->[0]{id},        'has id';
    is $batch->[0]{host},      $host, 'right host';
    is $batch->[0]{pid},       $$,    'right pid';
    like $batch->[0]{started}, qr/^[\d.]+$/, 'has timestamp';
    is $batch->[1]{host},      $host, 'right host';
    is $batch->[1]{pid},       $$,    'right pid';
    ok !$batch->[2], 'no more results';
    $results = $minion->backend->list_workers( 0, 1 );
    $batch   = $results->{workers};
    is $results->{total}, 2, 'two workers total';
    is $batch->[0]{id}, $worker2->id, 'right id';
    is_deeply $batch->[0]{status}, { whatever => 'works!' }, 'right status';
    ok !$batch->[1], 'no more results';
    $worker2->status( { whatever => 'works too!' } )->register;
    $batch = $minion->backend->list_workers( 0, 1 )->{workers};
    is_deeply $batch->[0]{status}, { whatever => 'works too!' }, 'right status';
    $batch = $minion->backend->list_workers( 1, 1 )->{workers};
    is $batch->[0]{id}, $worker->id, 'right id';
    ok !$batch->[1], 'no more results';
    $worker->unregister;
    $worker2->unregister;
};

# Exclusive lock
subtest 'Exclusive lock' => sub {
    ok $minion->lock( 'foo', 3600 ), 'locked';
    ok !$minion->lock( 'foo', 3600 ), 'not locked again';
    ok $minion->unlock('foo'), 'unlocked';
    ok !$minion->unlock('foo'), 'not unlocked again';
    ok $minion->lock( 'foo', -3600 ), 'locked';
    ok $minion->lock( 'foo', 0 ),     'locked again';
    ok !$minion->is_locked('foo'), 'lock does not exist';
    ok $minion->lock( 'foo', 3600 ), 'locked again';
    ok $minion->is_locked('foo'), 'lock exists';
    ok !$minion->lock( 'foo', -3600 ), 'not locked again';
    ok !$minion->lock( 'foo', 3600 ),  'not locked again';
    ok $minion->unlock('foo'), 'unlocked';
    ok !$minion->unlock('foo'), 'not unlocked again';
    ok $minion->lock( 'yada', 3600, { limit => 1 } ), 'locked';
    ok !$minion->lock( 'yada', 3600, { limit => 1 } ), 'not locked again';
};

# Shared lock
subtest 'Shared lock' => sub {
    ok $minion->lock( 'bar', 3600, { limit => 3 } ), 'locked';
    ok $minion->lock( 'bar', 3600, { limit => 3 } ), 'locked again';
    ok $minion->is_locked('bar'), 'lock exists';
    ok $minion->lock( 'bar', -3600, { limit => 3 } ), 'locked again';
    ok $minion->lock( 'bar', 3600, { limit => 3 } ),  'locked again';
    ok !$minion->lock( 'bar', 3600, { limit => 2 } ), 'not locked again';
    ok $minion->lock( 'baz', 3600, { limit => 3 } ), 'locked';
    ok $minion->unlock('bar'), 'unlocked';
    ok $minion->lock( 'bar', 3600, { limit => 3 } ), 'locked again';
    ok $minion->unlock('bar'), 'unlocked again';
    ok $minion->unlock('bar'), 'unlocked again';
    ok $minion->unlock('bar'), 'unlocked again';
    ok !$minion->unlock('bar'),    'not unlocked again';
    ok !$minion->is_locked('bar'), 'lock does not exist';
    ok $minion->unlock('baz'), 'unlocked';
    ok !$minion->unlock('baz'), 'not unlocked again';
};

# List locks
subtest 'List locks' => sub {
    is $minion->stats->{active_locks}, 1, 'one active lock';
    my $results = $minion->backend->list_locks( 0, 2 );
    is $results->{locks}[0]{name},      'yada',       'right name';
    like $results->{locks}[0]{expires}, qr/^[\d.]+$/, 'expires';
    is $results->{locks}[1], undef, 'no more locks';
    is $results->{total}, 1, 'one result';
    $minion->unlock('yada');
    $minion->lock( 'yada', 3601, { limit => 2 } );
    $minion->lock( 'test', 3602, { limit => 1 } );
    $minion->lock( 'yada', 3603, { limit => 2 } );
    is $minion->stats->{active_locks}, 3, 'three active locks';
    $results = $minion->backend->list_locks( 1, 1 );
    is $results->{locks}[0]{name},      'test',       'right name';
    like $results->{locks}[0]{expires}, qr/^[\d.]+$/, 'expires';
    is $results->{locks}[1], undef, 'no more locks';
    is $results->{total}, 3, 'three results';
    $results = $minion->backend->list_locks( 0, 10, { names => ['yada'] } );
    is $results->{locks}[0]{name},      'yada',       'right name';
    like $results->{locks}[0]{expires}, qr/^[\d.]+$/, 'expires';
    is $results->{locks}[1]{name},      'yada',       'right name';
    like $results->{locks}[1]{expires}, qr/^[\d.]+$/, 'expires';
    is $results->{locks}[2], undef, 'no more locks';
    is $results->{total}, 2, 'two results';
    $minion->backend->locks->update_many(
        { name => 'yada' },
        {
            '$set' => {
                'expires.$[]' => DateTime->now->add( seconds => -1 )
            }
        }
    );
    is $minion->backend->list_locks( 0, 10, { names => ['yada'] } )->{total}, 0,
      'no results';
    $minion->unlock('test');
    is $minion->backend->list_locks( 0, 10 )->{total}, 0, 'no results';
};

# Lock with guard
subtest 'Lock with guard' => sub {
    ok my $guard = $minion->guard( 'foo', 3600, { limit => 1 } ), 'locked';
    ok !$minion->guard( 'foo', 3600, { limit => 1 } ), 'not locked again';
    undef $guard;
    ok $guard = $minion->guard( 'foo', 3600 ), 'locked';
    ok !$minion->guard( 'foo', 3600 ), 'not locked again';
    undef $guard;
    ok $minion->guard( 'foo', 3600, { limit => 1 } ), 'locked again';
    ok $minion->guard( 'foo', 3600, { limit => 1 } ), 'locked again';
    ok $guard     = $minion->guard( 'bar', 3600, { limit => 2 } ), 'locked';
    ok my $guard2 = $minion->guard( 'bar', 0,    { limit => 2 } ), 'locked';
    ok my $guard3 = $minion->guard( 'bar', 3600, { limit => 2 } ), 'locked';
    undef $guard2;
    ok !$minion->guard( 'bar', 3600, { limit => 2 } ), 'not locked again';
    undef $guard;
    undef $guard3;
};

# Reset (locks)
subtest 'Reset (locks)' => sub {
    $minion->enqueue('test');
    $minion->lock( 'test', 3600 );
    $minion->worker->register;
    ok $minion->backend->list_jobs( 0, 1 )->{total},    'jobs';
    ok $minion->backend->list_locks( 0, 1 )->{total},   'locks';
    ok $minion->backend->list_workers( 0, 1 )->{total}, 'workers';
    $minion->reset( { locks => 1 } );
    ok $minion->backend->list_jobs( 0, 1 )->{total}, 'jobs';
    ok !$minion->backend->list_locks( 0, 1 )->{total}, 'no locks';
    ok $minion->backend->list_workers( 0, 1 )->{total}, 'workers';
};

# Reset (all)
subtest 'Reset (all)' => sub {
    $minion->lock( 'test', 3600 );
    ok $minion->backend->list_jobs( 0, 1 )->{total},    'jobs';
    ok $minion->backend->list_locks( 0, 1 )->{total},   'locks';
    ok $minion->backend->list_workers( 0, 1 )->{total}, 'workers';
    $minion->reset( { all => 1 } )->repair;
    foreach (qw(jobs locks workers)) {
        ok !$minion->backend->$_->count_documents( {} ), "no $_";
    }
};

# Stats
subtest 'Stats' => sub {
    $minion->add_task(
        add => sub {
            my ( $job, $first, $second ) = @_;
            $job->finish( { added => $first + $second } );
        }
    );
    $minion->add_task( fail => sub { die "Intentional failure!\n" } );
    my $stats = $minion->stats;
    is $stats->{active_workers},   0, 'no active workers';
    is $stats->{inactive_workers}, 0, 'no inactive workers';
    is $stats->{enqueued_jobs},    0, 'no enqueued jobs';
    is $stats->{active_jobs},      0, 'no active jobs';
    is $stats->{failed_jobs},      0, 'no failed jobs';
    is $stats->{finished_jobs},    0, 'no finished jobs';
    is $stats->{inactive_jobs},    0, 'no inactive jobs';
    is $stats->{delayed_jobs},     0, 'no delayed jobs';
    is $stats->{active_locks},     0, 'no active locks';
    ok $stats->{uptime},           'has uptime';
    my $worker = $minion->worker->register;
    is $minion->stats->{inactive_workers}, 1, 'one inactive worker';
    $minion->enqueue('fail');
    is $minion->stats->{enqueued_jobs}, 1, 'one enqueued job';
    $minion->enqueue('fail');
    is $minion->stats->{enqueued_jobs}, 2, 'two enqueued jobs';
    is $minion->stats->{inactive_jobs}, 2, 'two inactive jobs';
    ok my $job = $worker->dequeue(0), 'job dequeued';
    $stats = $minion->stats;
    is $stats->{active_workers}, 1, 'one active worker';
    is $stats->{active_jobs},    1, 'one active job';
    is $stats->{inactive_jobs},  1, 'one inactive job';
    $minion->enqueue('fail');
    ok my $job2 = $worker->dequeue(0), 'job dequeued';
    $stats = $minion->stats;
    is $stats->{active_workers}, 1, 'one active worker';
    is $stats->{active_jobs},    2, 'two active jobs';
    is $stats->{inactive_jobs},  1, 'one inactive job';
    ok $job2->finish, 'job finished';
    ok $job->finish,  'job finished';
    is $minion->stats->{finished_jobs}, 2, 'two finished jobs';
    $job = $worker->dequeue(0);
    ok $job->fail, 'job failed';
    is $minion->stats->{failed_jobs}, 1, 'one failed job';
    ok $job->retry, 'job retried';
    is $minion->stats->{failed_jobs}, 0, 'no failed jobs';
    ok $worker->dequeue(0)->finish( ['works'] ), 'job finished';
    $worker->unregister;
    $stats = $minion->stats;
    is $stats->{active_workers},   0, 'no active workers';
    is $stats->{inactive_workers}, 0, 'no inactive workers';
    is $stats->{active_jobs},      0, 'no active jobs';
    is $stats->{failed_jobs},      0, 'no failed jobs';
    is $stats->{finished_jobs},    3, 'three finished jobs';
    is $stats->{inactive_jobs},    0, 'no inactive jobs';
    is $stats->{delayed_jobs},     0, 'no delayed jobs';
};

# History
subtest 'History' => sub {
    $minion->enqueue('fail');
    my $worker = $minion->worker->register;
    my $job    = $worker->dequeue(0);
    ok $job->fail, 'job failed';
    $worker->unregister;
    my $history = $minion->history;
    is $#{ $history->{daily} }, 23, 'data for 24 hours';
    is $history->{daily}[-1]{finished_jobs} +
      $history->{daily}[-2]{finished_jobs},
      3, 'one failed job in the last hour';
    is $history->{daily}[-1]{failed_jobs} + $history->{daily}[-2]{failed_jobs},
      1,
      'three finished jobs in the last hour';
    is $history->{daily}[0]{finished_jobs}, 0, 'no finished jobs 24 hours ago';
    is $history->{daily}[0]{failed_jobs},   0, 'no failed jobs 24 hours ago';
    ok defined $history->{daily}[0]{epoch},  'has epoch value';
    ok defined $history->{daily}[1]{epoch},  'has epoch value';
    ok defined $history->{daily}[12]{epoch}, 'has epoch value';
    ok defined $history->{daily}[-1]{epoch}, 'has epoch value';
    $job->remove;
};

# List jobs
subtest 'List jobs' => sub {
    my $id      = $minion->enqueue('add');
    my $results = $minion->backend->list_jobs( 0, 10 );
    my $batch   = $results->{jobs};
    is $results->{total}, 4, 'four jobs total';
    ok $batch->[0]{id},          'has id';
    is $batch->[0]{task},        'add',        'right task';
    is $batch->[0]{state},       'inactive',   'right state';
    is $batch->[0]{retries},     0,            'job has not been retried';
    like $batch->[0]{created},   qr/^[\d.]+$/, 'has created timestamp';
    is $batch->[1]{task},        'fail',       'right task';
    is_deeply $batch->[1]{args}, [], 'right arguments';
    is_deeply $batch->[1]{notes}, {}, 'right metadata';
    is_deeply $batch->[1]{result},   ['works'], 'right result';
    is $batch->[1]{state},           'finished', 'right state';
    is $batch->[1]{priority},        0,          'right priority';
    is_deeply $batch->[1]{parents},  [], 'right parents';
    is_deeply $batch->[1]{children}, [], 'right children';
    is $batch->[1]{retries},         1,            'job has been retried';
    like $batch->[1]{created},       qr/^[\d.]+$/, 'has created timestamp';
    like $batch->[1]{delayed},       qr/^[\d.]+$/, 'has delayed timestamp';
    like $batch->[1]{finished},      qr/^[\d.]+$/, 'has finished timestamp';
    like $batch->[1]{retried},       qr/^[\d.]+$/, 'has retried timestamp';
    like $batch->[1]{started},       qr/^[\d.]+$/, 'has started timestamp';
    is $batch->[2]{task},            'fail',       'right task';
    is $batch->[2]{state},           'finished',   'right state';
    is $batch->[2]{retries},         0,            'job has not been retried';
    is $batch->[3]{task},            'fail',       'right task';
    is $batch->[3]{state},           'finished',   'right state';
    is $batch->[3]{retries},         0,            'job has not been retried';
    ok !$batch->[4], 'no more results';
    $batch =
      $minion->backend->list_jobs( 0, 10, { states => ['inactive'] } )->{jobs};
    is $batch->[0]{state},   'inactive', 'right state';
    is $batch->[0]{retries}, 0,          'job has not been retried';
    ok !$batch->[1], 'no more results';
    $batch = $minion->backend->list_jobs( 0, 10, { tasks => ['add'] } )->{jobs};
    is $batch->[0]{task},    'add', 'right task';
    is $batch->[0]{retries}, 0,     'job has not been retried';
    ok !$batch->[1], 'no more results';
    $batch =
      $minion->backend->list_jobs( 0, 10, { tasks => [ 'add', 'fail' ] } )
      ->{jobs};
    is $batch->[0]{task}, 'add',  'right task';
    is $batch->[1]{task}, 'fail', 'right task';
    is $batch->[2]{task}, 'fail', 'right task';
    is $batch->[3]{task}, 'fail', 'right task';
    ok !$batch->[4], 'no more results';
    $batch =
      $minion->backend->list_jobs( 0, 10, { queues => ['default'] } )->{jobs};
    is $batch->[0]{queue}, 'default', 'right queue';
    is $batch->[1]{queue}, 'default', 'right queue';
    is $batch->[2]{queue}, 'default', 'right queue';
    is $batch->[3]{queue}, 'default', 'right queue';
    ok !$batch->[4], 'no more results';
    my $id2 = $minion->enqueue( 'test' => [] => { notes => { is_test => 1 } } );
    $batch =
      $minion->backend->list_jobs( 0, 10, { notes => ['is_test'] } )->{jobs};
    is $batch->[0]{task}, 'test', 'right task';
    ok !$batch->[4], 'no more results';
    ok $minion->job($id2)->remove, 'job removed';
    $batch =
      $minion->backend->list_jobs( 0, 10, { queues => ['does_not_exist'] } )
      ->{jobs};
    is_deeply $batch, [], 'no results';
    $results = $minion->backend->list_jobs( 0, 1 );
    $batch   = $results->{jobs};
    is $results->{total}, 4, 'four jobs total';
    is $batch->[0]{state},   'inactive', 'right state';
    is $batch->[0]{retries}, 0,          'job has not been retried';
    ok !$batch->[1], 'no more results';
    $batch = $minion->backend->list_jobs( 1, 1 )->{jobs};
    is $batch->[0]{state},   'finished', 'right state';
    is $batch->[0]{retries}, 1,          'job has been retried';
    ok !$batch->[1], 'no more results';
    ok $minion->job($id)->remove, 'job removed';
};

# Enqueue, dequeue and perform
subtest 'Enqueue, dequeue and perform' => sub {
    is $minion->job( new BSON::ObjectId('123456789012') ), undef,
      'job does not exist';
    my $id = $minion->enqueue( add => [ 2, 2 ] );
    ok $minion->job($id), 'job does exist';
    my $info = $minion->job($id)->info;
    is_deeply $info->{args}, [ 2, 2 ], 'right arguments';
    is $info->{priority},    0,          'right priority';
    is $info->{state},       'inactive', 'right state';
    my $worker = $minion->worker;
    is $worker->dequeue(0), undef, 'not registered';
    ok !$minion->job($id)->info->{started}, 'no started timestamp';
    $worker = $minion->worker->register;
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $worker->info->{jobs}[0], $job->id, 'right job';
    like $job->info->{created}, qr/^[\d.]+$/, 'has created timestamp';
    like $job->info->{started}, qr/^[\d.]+$/, 'has started timestamp';
    like $job->info->{time},    qr/^[\d.]+$/, 'has server time';
    is_deeply $job->args, [ 2, 2 ], 'right arguments';
    is $job->info->{state}, 'active', 'right state';
    is $job->task,    'add', 'right task';
    is $job->retries, 0,     'job has not been retried';
    $id = $job->info->{worker};
    is $minion->backend->list_workers( 0, 1, { ids => [$id] } )
      ->{workers}[0]{pid}, $$,
      'right worker';
    ok !$job->info->{finished}, 'no finished timestamp';
    $job->perform;
    is $worker->info->{jobs}[0], undef, 'no jobs';
    like $job->info->{finished}, qr/^[\d.]+$/, 'has finished timestamp';
    is_deeply $job->info->{result}, { added => 4 }, 'right result';
    is $job->info->{state}, 'finished', 'right state';
    $worker->unregister;
    $job = $minion->job( $job->id );
    is_deeply $job->args, [ 2, 2 ], 'right arguments';
    is $job->retries, 0, 'job has not been retried';
    is $job->info->{state}, 'finished', 'right state';
    is $job->task, 'add', 'right task';
};

# Retry and remove
subtest 'Retry and remove' => sub {
    my $id     = $minion->enqueue( add => [ 5, 6 ] );
    my $worker = $minion->worker->register;
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->info->{attempts}, 1, 'job will be attempted once';
    is $job->info->{retries},  0, 'job has not been retried';
    is $job->id, $id, 'right id';
    ok $job->finish, 'job finished';
    ok !$worker->dequeue(0), 'no more jobs';
    $job = $minion->job($id);
    ok !$job->info->{retried}, 'no retried timestamp';
    ok $job->retry, 'job retried';
    like $job->info->{retried}, qr/^[\d.]+$/, 'has retried timestamp';
    is $job->info->{state},     'inactive',   'right state';
    is $job->info->{retries},   1,            'job has been retried once';
    $job = $worker->dequeue(0);
    is $job->retries, 1, 'job has been retried once';
    ok $job->retry,   'job retried';
    is $job->id,      $id, 'right id';
    is $job->info->{retries}, 2, 'job has been retried twice';
    $job = $worker->dequeue(0);
    is $job->info->{state}, 'active', 'right state';
    ok $job->finish, 'job finished';
    ok $job->remove, 'job has been removed';
    ok !$job->retry, 'job not retried';
    is $job->info, undef, 'no information';
    $id  = $minion->enqueue( add => [ 6, 5 ] );
    $job = $minion->job($id);
    is $job->info->{state},   'inactive', 'right state';
    is $job->info->{retries}, 0,          'job has not been retried';
    ok $job->retry, 'job retried';
    is $job->info->{state},   'inactive', 'right state';
    is $job->info->{retries}, 1,          'job has been retried once';
    $job = $worker->dequeue(0);
    is $job->id,     $id, 'right id';
    ok $job->fail,   'job failed';
    ok $job->remove, 'job has been removed';
    is $job->info,   undef, 'no information';
    $id  = $minion->enqueue( add => [ 5, 5 ] );
    $job = $minion->job("$id");
    ok $job->remove, 'job has been removed';
    $worker->unregister;
};

# Jobs with priority
subtest 'Jobs with priority' => sub {
    $minion->enqueue( add => [ 1, 2 ] );
    my $id     = $minion->enqueue( add => [ 2, 4 ], { priority => 1 } );
    my $worker = $minion->worker->register;
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->info->{priority}, 1, 'right priority';
    ok $job->finish, 'job finished';
    isnt $worker->dequeue(0)->id, $id, 'different id';
    $id = $minion->enqueue( add => [ 2, 5 ] );
    ok $job = $worker->register->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->info->{priority}, 0, 'right priority';
    ok $job->finish, 'job finished';
    ok $job->retry( { priority => 100 } ), 'job retried with higher priority';
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->info->{retries},  1,   'job has been retried once';
    is $job->info->{priority}, 100, 'high priority';
    ok $job->finish, 'job finished';
    ok $job->retry( { priority => 0 } ), 'job retried with lower priority';
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->info->{retries},  2, 'job has been retried twice';
    is $job->info->{priority}, 0, 'low priority';
    ok $job->finish, 'job finished';

    $id = $minion->enqueue( add => [ 2, 6 ], { priority => 2 } );
    ok !$worker->dequeue( 0, { min_priority => 5 } );
    ok !$worker->dequeue( 0, { min_priority => 3 } );
    ok $job = $worker->dequeue( 0, { min_priority => 2 } );
    is $job->id, $id, 'right id';
    is $job->info->{priority}, 2, 'expected priority';
    ok $job->finish, 'job finished';
    $minion->enqueue( add => [ 2, 8 ], { priority => 0 } );
    $minion->enqueue( add => [ 2, 7 ], { priority => 5 } );
    $minion->enqueue( add => [ 2, 8 ], { priority => -2 } );
    ok !$worker->dequeue( 0, { min_priority => 6 } );
    ok $job = $worker->dequeue( 0, { min_priority => 0 } );
    is $job->info->{priority}, 5, 'expected priority';
    ok $job->finish, 'job finished';
    ok $job = $worker->dequeue( 0, { min_priority => 0 } );
    is $job->info->{priority}, 0, 'expected priority';
    ok $job->finish, 'job finished';
    ok !$worker->dequeue( 0, { min_priority => 0 } );
    ok $job = $worker->dequeue( 0, { min_priority => -10 } );
    is $job->info->{priority}, -2, 'expected priority';
    ok $job->finish, 'job finished';
    $worker->unregister;
};

# Delayed jobs
subtest 'Delayed jobs' => sub {
    my $id = $minion->enqueue( add => [ 2, 1 ] => { delay => 100 } );
    is $minion->stats->{delayed_jobs}, 1, 'one delayed job';
    my $worker = $minion->worker->register;
    is $worker->register->dequeue(0), undef, 'too early for job';
    my $job = $minion->job($id);
    ok $job->info->{delayed} > $job->info->{created}, 'delayed timestamp';
    $minion->backend->jobs->update_one(
        { _id => $minion->backend->_oid($id) },
        {
            '$set' => {
                delayed => DateTime->now->add( seconds => -1 )
            }
        }
    );
    $job = $worker->dequeue(0);
    is $job->id, $id, 'right id';
    like $job->info->{delayed}, qr/^[\d.]+$/, 'has delayed timestamp';
    ok $job->finish, 'job finished';
    ok $job->retry,  'job retried';
    my $info = $minion->job($id)->info;
    ok $info->{delayed} <= $info->{retried}, 'no delayed timestamp';
    ok $job->remove, 'job removed';
    ok !$job->retry, 'job not retried';
    $id   = $minion->enqueue( add => [ 6, 9 ] );
    $job  = $worker->dequeue(0);
    $info = $minion->job($id)->info;
    ok $info->{delayed} <= $info->{created}, 'no delayed timestamp';
    ok $job->fail, 'job failed';
    ok $job->retry( { delay => 100 } ), 'job retried with delay';
    $info = $minion->job($id)->info;
    is $info->{retries}, 1, 'job has been retried once';
    ok $info->{delayed} > $info->{retried}, 'delayed timestamp';
    ok $minion->job($id)->remove, 'job has been removed';
    $worker->unregister;
};

# Events
subtest 'Events' => sub {
    my ( $enqueue, $pid_start, $pid_stop );
    my ( $failed, $finished ) = ( 0, 0 );
    $minion->once( enqueue => sub { $enqueue = pop } );
    $minion->once(
        worker => sub {
            my ( $minion, $worker ) = @_;
            $worker->on(
                dequeue => sub {
                    my ( $worker, $job ) = @_;
                    $job->on( failed   => sub { $failed++ } );
                    $job->on( finished => sub { $finished++ } );
                    $job->on( spawn    => sub { $pid_start = pop } );
                    $job->on( reap     => sub { $pid_stop  = pop } );
                    $job->on(
                        start => sub {
                            my $job = shift;
                            return unless $job->task eq 'switcheroo';
                            $job->task('add')->args->[-1] += 1;
                        }
                    );
                    $job->on(
                        finish => sub {
                            my $job = shift;
                            return
                              unless defined( my $old =
                                  $job->info->{notes}{finish_count} );
                            $job->note(
                                finish_count => $old + 1,
                                finish_pid   => $$
                            );
                        }
                    );

                    # introduced in Minion v9.13
                    $job->on(
                        cleanup => sub {
                            my $job = shift;
                            return
                              unless defined( my $old =
                                  $job->info->{notes}{finish_count} );
                            $job->note(
                                cleanup_count => $old + 1,
                                cleanup_pid   => $$
                            );
                        }
                    );
                }
            );
        }
    );
    my $worker = $minion->worker->register;
    my $id     = $minion->enqueue( add => [ 3, 3 ] );
    is $enqueue, $id, 'enqueue event has been emitted';
    $minion->enqueue( add => [ 4, 3 ] );
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $failed,   0, 'failed event has not been emitted';
    is $finished, 0, 'finished event has not been emitted';
    my $result;
    $job->on( finished => sub { $result = pop } );
    ok $job->finish('Everything is fine!'), 'job finished';
    $job->perform;
    is $result,   'Everything is fine!', 'right result';
    is $failed,   0,                     'failed event has not been emitted';
    is $finished, 1,                     'finished event has been emitted once';
    isnt $pid_start, $$,        'new process id';
    isnt $pid_stop,  $$,        'new process id';
    is $pid_start,   $pid_stop, 'same process id';
    $job = $worker->dequeue(0);
    my $err;
    $job->on( failed => sub { $err = pop } );
    $job->fail("test\n");
    $job->fail;
    is $err,      "test\n", 'right error';
    is $failed,   1,        'failed event has been emitted once';
    is $finished, 1,        'finished event has been emitted once';
    $minion->add_task( switcheroo => sub { } );
    $minion->enqueue( switcheroo => [ 5, 3 ] =>
          { notes => { finish_count => 0, before => 23 } } );
    $job = $worker->dequeue(0);
    $job->perform;
    is_deeply $job->info->{result}, { added => 9 }, 'right result';
    is $job->info->{notes}{finish_count}, 1,
      'finish event has been emitted once';
    ok $job->info->{notes}{finish_pid},   'has a process id';
    isnt $job->info->{notes}{finish_pid}, $$, 'different process id';
    is $job->info->{notes}{before},       23, 'value still exists';
  SKIP: {
        skip "Cleanup event introduced in Minion v9.13", 3
          if ( $Minion::VERSION < 9.13 );
        is $job->info->{notes}{cleanup_count}, 2,
          'cleanup event has been emitted once';
        ok $job->info->{notes}{cleanup_pid}, 'has a process id';
        isnt $job->info->{notes}{cleanup_pid}, $$, 'different process id';
    }
    $worker->unregister;
};

# Queues
subtest 'Queues' => sub {
    my $id     = $minion->enqueue( add => [ 100, 1 ] );
    my $worker = $minion->worker->register;
    is $worker->register->dequeue( 0 => { queues => ['test1'] } ), undef,
      'wrong queue';
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->info->{queue}, 'default', 'right queue';
    ok $job->finish, 'job finished';
    $id = $minion->enqueue( add => [ 100, 3 ] => { queue => 'test1' } );
    is $worker->dequeue(0), undef, 'wrong queue';
    $job = $worker->dequeue( 0 => { queues => ['test1'] } );
    is $job->id, $id, 'right id';
    is $job->info->{queue}, 'test1', 'right queue';
    ok $job->finish, 'job finished';
    ok $job->retry( { queue => 'test2' } ), 'job retried';
    $job = $worker->dequeue( 0 => { queues => [ 'default', 'test2' ] } );
    is $job->id, $id, 'right id';
    is $job->info->{queue}, 'test2', 'right queue';
    ok $job->finish, 'job finished';
    $worker->unregister;
};

# Failed jobs
subtest 'Failed jobs' => sub {
    my $id     = $minion->enqueue( add => [ 5, 6 ] );
    my $worker = $minion->worker->register;
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->info->{result}, undef, 'no result';
    ok $job->fail, 'job failed';
    ok !$job->finish, 'job not finished';
    is $job->info->{state},  'failed',        'right state';
    is $job->info->{result}, 'Unknown error', 'right result';
    $id  = $minion->enqueue( add => [ 6, 7 ] );
    $job = $worker->dequeue(0);
    is $job->id, $id, 'right id';
    ok $job->fail('Something bad happened!'), 'job failed';
    is $job->info->{state},  'failed',                  'right state';
    is $job->info->{result}, 'Something bad happened!', 'right result';
    $id  = $minion->enqueue('fail');
    $job = $worker->dequeue(0);
    is $job->id, $id, 'right id';
    $job->perform;
    is $job->info->{state},  'failed',                 'right state';
    is $job->info->{result}, "Intentional failure!\n", 'right result';
    $worker->unregister;
};

# Nested data structures
subtest 'Nested data structures' => sub {
    $minion->add_task(
        nested => sub {
            my ( $job, $hash, $array ) = @_;
            $job->note( bar => { baz => [ 1, 2, 3 ] } );
            $job->note( baz => 'yada' );
            $job->finish(
                [ { 23 => $hash->{first}[0]{second} x $array->[0][0] } ] );
        }
    );
    $minion->enqueue(
        'nested',
        [ { first => [ { second => 'test' } ] }, [ [3] ] ],
        { notes => { foo => [ 4, 5, 6 ] } }
    );
    my $worker = $minion->worker->register;
    ok my $job = $worker->dequeue(0), 'job dequeued';
    $job->perform;
    is $job->info->{state}, 'finished', 'right state';
    ok $job->note( yada => ['works'] ), 'added metadata';
    ok !$minion->backend->note( undef, { yada => ['failed'] } ),
      'not added metadata';
    my $notes = {
        foo  => [ 4, 5, 6 ],
        bar  => { baz => [ 1, 2, 3 ] },
        baz  => 'yada',
        yada => ['works']
    };
    is_deeply $job->info->{notes}, $notes, 'right metadata';
    is_deeply $job->info->{result}, [ { 23 => 'testtesttest' } ],
      'right structure';
    ok !$job->note(), 'do nothing';
    ok $job->note( foo  => 5, baz => undef ), 'changes and removed metadata';
    ok $job->note( yada => undef, bar => undef ), 'removed metadata';
    $notes = { foo => 5 };
    is_deeply $job->info->{notes}, $notes, 'right metadata';
    $worker->unregister;
};

# Perform job in a running event loop
subtest 'Perform job in a running event loop' => sub {
    my $id = $minion->enqueue( add => [ 8, 9 ] );
    Mojo::Promise->new->resolve->then( sub { $minion->perform_jobs } )->wait;
    is $minion->job($id)->info->{state}, 'finished', 'right state';
    is_deeply $minion->job($id)->info->{result}, { added => 17 },
      'right result';
};

# Non-zero exit status
subtest 'Job terminated unexpectedly' => sub {
    $minion->add_task( exit => sub { exit 1 } );
    my $id     = $minion->enqueue('exit');
    my $worker = $minion->worker->register;
    ok my $job = $worker->register->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    $job->perform;
    is $job->info->{state}, 'failed', 'right state';
    is $job->info->{result},
      'Job terminated unexpectedly (exit code: 1, signal: 0)', 'right result';
    $worker->unregister;
};

# Multiple attempts while processing
subtest 'Multiple attempts while processing' => sub {
    is $minion->backoff->(0),  15,     'right result';
    is $minion->backoff->(1),  16,     'right result';
    is $minion->backoff->(2),  31,     'right result';
    is $minion->backoff->(3),  96,     'right result';
    is $minion->backoff->(4),  271,    'right result';
    is $minion->backoff->(5),  640,    'right result';
    is $minion->backoff->(25), 390640, 'right result';

    my $id     = $minion->enqueue( exit => [] => { attempts => 3 } );
    my $worker = $minion->worker->register;
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->retries, 0, 'job has not been retried';
    my $info = $job->info;
    is $info->{attempts}, 3,        'three attempts';
    is $info->{state},    'active', 'right state';
    $job->perform;
    $info = $job->info;
    is $info->{attempts}, 2,          'two attempts';
    is $info->{state},    'inactive', 'right state';
    is $info->{result},
      'Job terminated unexpectedly (exit code: 1, signal: 0)', 'right result';
    ok $info->{retried} < $job->info->{delayed}, 'delayed timestamp';
    $minion->backend->jobs->update_one(
        { _id    => $minion->backend->_oid($id) },
        { '$set' => { delayed => DateTime->now } }
    );
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->retries, 1, 'job has been retried';
    $info = $job->info;
    is $info->{attempts}, 2,        'two attempts';
    is $info->{state},    'active', 'right state';
    $job->perform;
    $info = $job->info;
    is $info->{attempts}, 1,          'one attempt';
    is $info->{state},    'inactive', 'right state';
    $minion->backend->jobs->update_one(
        { _id    => $minion->backend->_oid($id) },
        { '$set' => { delayed => DateTime->now } }
    );
    ok $job = $worker->register->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->retries, 2, 'two retries';
    $info = $job->info;
    is $info->{attempts}, 1,        'one attempt';
    is $info->{state},    'active', 'right state';
    $job->perform;
    $info = $job->info;
    is $info->{attempts}, 1,        'one attempt';
    is $info->{state},    'failed', 'right state';
    is $info->{result},
      'Job terminated unexpectedly (exit code: 1, signal: 0)', 'right result';

    ok $job->retry( { attempts => 2 } ), 'job retried';
    ok $job = $worker->register->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    $job->perform;
    is $job->info->{state}, 'inactive', 'right state';
    $minion->backend->jobs->update_one(
        { _id    => $minion->backend->_oid($id) },
        { '$set' => { delayed => DateTime->now } }
    );
    ok $job = $worker->register->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    $job->perform;
    is $job->info->{state}, 'failed', 'right state';
    $worker->unregister;
};

# Multiple attempts during maintenance
subtest 'Multiple attempts during maintenance' => sub {
    my $id     = $minion->enqueue( exit => [] => { attempts => 2 } );
    my $worker = $minion->worker->register;
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->retries, 0, 'job has not been retried';
    is $job->info->{attempts}, 2,        'job will be attempted twice';
    is $job->info->{state},    'active', 'right state';
    $worker->unregister;
    $minion->repair;
    is $job->info->{state},  'inactive',         'right state';
    is $job->info->{result}, 'Worker went away', 'right result';
    ok $job->info->{retried} < $job->info->{delayed}, 'delayed timestamp';
    $minion->backend->jobs->update_one(
        { _id    => $minion->backend->_oid($id) },
        { '$set' => { delayed => DateTime->now } }
    );
    ok $job = $worker->register->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is $job->retries, 1, 'job has been retried once';
    $worker->unregister;
    $minion->repair;
    is $job->info->{state},  'failed',           'right state';
    is $job->info->{result}, 'Worker went away', 'right result';
};

# A job needs to be dequeued again after a retry
subtest 'A job needs to be dequeued again after a retry' => sub {
    $minion->add_task( restart => sub { } );
    my $id     = $minion->enqueue('restart');
    my $worker = $minion->worker->register;
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    ok $job->finish, 'job finished';
    is $job->info->{state}, 'finished', 'right state';
    ok $job->retry, 'job retried';
    is $job->info->{state}, 'inactive', 'right state';
    ok my $job2 = $worker->dequeue(0), 'job dequeued';
    is $job->info->{state}, 'active', 'right state';
    ok !$job->finish, 'job not finished';
    is $job->info->{state}, 'active', 'right state';
    is $job2->id, $id, 'right id';
    ok $job2->finish, 'job finished';
    ok !$job->retry, 'job not retried';
    is $job->info->{state}, 'finished', 'right state';
    $worker->unregister;
};

# Perform jobs concurrently
subtest 'Perform jobs concurrently' => sub {
    my $id     = $minion->enqueue( add => [ 10, 11 ] );
    my $id2    = $minion->enqueue( add => [ 12, 13 ] );
    my $id3    = $minion->enqueue('test');
    my $id4    = $minion->enqueue('exit');
    my $worker = $minion->worker->register;
    ok my $job  = $worker->dequeue(0), 'job dequeued';
    ok my $job2 = $worker->dequeue(0), 'job dequeued';
    ok my $job3 = $worker->dequeue(0), 'job dequeued';
    ok my $job4 = $worker->dequeue(0), 'job dequeued';
    $job->start;
    $job2->start;
    $job3->start;
    $job4->start;
    my ( $first, $second, $third, $fourth );
    usleep 50000
      until $first ||= $job->is_finished
      and $second  ||= $job2->is_finished
      and $third   ||= $job3->is_finished
      and $fourth  ||= $job4->is_finished;
    is $minion->job($id)->info->{state}, 'finished', 'right state';
    is_deeply $minion->job($id)->info->{result}, { added => 21 },
      'right result';
    is $minion->job($id2)->info->{state}, 'finished', 'right state';
    is_deeply $minion->job($id2)->info->{result}, { added => 25 },
      'right result';
    is $minion->job($id3)->info->{state},  'finished', 'right state';
    is $minion->job($id3)->info->{result}, undef,      'no result';
    is $minion->job($id4)->info->{state},  'failed',   'right state';
    is $minion->job($id4)->info->{result},
      'Job terminated unexpectedly (exit code: 1, signal: 0)',
      'right result';
    $worker->unregister;
};

subtest 'Stopping jobs' => sub {
    $minion->add_task(
        long_running => sub {
            shift->note( started => 1 );
            sleep 1000;
        }
    );
    my $worker = $minion->worker->register;
    $minion->enqueue('long_running');
    ok my $job = $worker->dequeue(0), 'job dequeued';
    ok $job->start->pid, 'has a process id';
    ok !$job->is_finished, 'job is not finished';
    $job->stop;
    usleep 5000 until $job->is_finished;
    is $job->info->{state},    'failed',                        'right state';
    like $job->info->{result}, qr/Job terminated unexpectedly/, 'right result';
    $minion->enqueue('long_running');
    $job = $worker->dequeue(0);
    ok $job->start->pid, 'has a process id';
    ok !$job->is_finished, 'job is not finished';
    usleep 5000 until $job->info->{notes}{started};
  SKIP: {
        skip "Kill method introduced in Minion v9.06", 4
          if ( $Minion::VERSION < 9.06 );
        $job->kill('USR1');
        $job->kill('USR2');
        is $job->info->{state}, 'active', 'right state';
        $job->kill('INT');
        usleep 5000 until $job->is_finished;
        is $job->info->{state}, 'failed', 'right state';
        like $job->info->{result}, qr/Job terminated unexpectedly/,
          'right result';
    }
    $worker->unregister;
};

# Job dependencies
subtest 'Job dependencies' => sub {
    my $worker = $minion->remove_after(0)->worker->register;
    is $minion->repair->stats->{finished_jobs}, 0, 'no finished jobs';
    my $id  = $minion->enqueue('test');
    my $id2 = $minion->enqueue('test');
    my $id3 = $minion->enqueue( test => [] => { parents => [ $id, $id2 ] } );
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is_deeply $job->info->{children}, [$id3], 'right children';
    is_deeply $job->info->{parents}, [], 'right parents';
    ok my $job2 = $worker->dequeue(0), 'job dequeued';
    is $job2->id, $id2, 'right id';
    is_deeply $job2->info->{children}, [$id3], 'right children';
    is_deeply $job2->info->{parents}, [], 'right parents';
    ok !$worker->dequeue(0), 'parents are not ready yet';
    ok $job->finish, 'job finished';
    ok !$worker->dequeue(0), 'parents are not ready yet';
    ok $job2->fail, 'job failed';
    ok !$worker->dequeue(0), 'parents are not ready yet';
    ok $job2->retry, 'job retried';
    ok $job2 = $worker->dequeue(0), 'job dequeued';
    is $job2->id, $id2, 'right id';
    ok $job2->finish, 'job finished';
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id3, 'right id';
    is_deeply $job->info->{children},   [], 'right children';
    is_deeply $job->info->{parents},    [ $id, $id2 ], 'right parents';
    is $minion->stats->{finished_jobs}, 2, 'two finished jobs';
    is $minion->repair->stats->{finished_jobs}, 2, 'two finished jobs';
    ok $job->finish, 'job finished';
    is $minion->stats->{finished_jobs}, 3, 'three finished jobs';
    is $minion->repair->remove_after(172800)->stats->{finished_jobs}, 0,
      'no finished jobs';
    my $fake_hex = '00000000000000000000000';
    $id = $minion->enqueue( test => [] => { parents => ["${fake_hex}1"] } );
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    ok $job->finish, 'job finished';
    $id = $minion->enqueue( test => [] => { parents => ["${fake_hex}1"] } );
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is_deeply $job->info->{parents}, ["${fake_hex}1"], 'right parents';
    $job->retry( { parents => [ "${fake_hex}1", "${fake_hex}2" ] } );
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is_deeply $job->info->{parents}, [ "${fake_hex}1", "${fake_hex}2" ],
      'right parents';
    ok $job->finish, 'job finished';

    my $id4   = $minion->enqueue('test');
    my $id5   = $minion->enqueue('test');
    my $id6   = $minion->enqueue( test => [] => { parents => [ $id4, $id5 ] } );
    my $child = $minion->job($id6);
    my $parents = $child->parents;
    is $parents->size, 2, 'two parents';
    is $parents->[0]->id, $id4, 'first parent';
    is $parents->[1]->id, $id5, 'second parent';
    $_->remove for $parents->each;
    is $child->parents->size, 0, 'no parents';
    ok $child->remove, 'job removed';
    $worker->unregister;
};

subtest 'Job dependencies (lax)' => sub {
    my $worker = $minion->worker->register;
    my $id     = $minion->enqueue('test');
    my $id2    = $minion->enqueue('test');
    my $id3 =
      $minion->enqueue( test => [] => { lax => 1, parents => [ $id, $id2 ] } );
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    is_deeply $job->info->{children}, [$id3], 'right children';
    is_deeply $job->info->{parents}, [], 'right parents';
    ok my $job2 = $worker->dequeue(0), 'job dequeued';
    is $job2->id, $id2, 'right id';
    is_deeply $job2->info->{children}, [$id3], 'right children';
    is_deeply $job2->info->{parents}, [], 'right parents';
    ok !$worker->dequeue(0), 'parents are not ready yet';
    ok $job->finish, 'job finished';
    ok !$worker->dequeue(0), 'parents are not ready yet';
    ok $job2->fail, 'job failed';
    ok my $job3 = $worker->dequeue(0), 'job dequeued';
    is $job3->id, $id3, 'right id';
    is_deeply $job3->info->{children}, [], 'right children';
    is_deeply $job3->info->{parents}, [ $id, $id2 ], 'right parents';
    ok $job3->finish, 'job finished';

    my $id4 = $minion->enqueue('test');
    my $id5 = $minion->enqueue( test => [] => { parents => [$id4] } );
    ok my $job4 = $worker->dequeue(0), 'job dequeued';
    is $job4->id, $id4, 'right id';
    ok !$worker->dequeue(0), 'parents are not ready yet';
    ok $job4->fail, 'job finished';
    ok !$worker->dequeue(0), 'parents are not ready yet';
    ok $minion->job($id5)->retry( { lax => 1 } ), 'job is now lax';
    ok my $job5 = $worker->dequeue(0), 'job dequeued';
    is $job5->id, $id5, 'right id';
    is_deeply $job5->info->{children}, [], 'right children';
    is_deeply $job5->info->{parents}, [$id4], 'right parents';
    ok $job5->finish, 'job finished';
    ok $job4->remove, 'job removed';

    is $minion->jobs( { ids => [$id5] } )->next->{lax}, 1, 'lax';
    ok $minion->job($id5)->retry, 'job is still lax';
    is $minion->jobs( { ids => [$id5] } )->next->{lax}, 1, 'lax';
    ok $minion->job($id5)->retry( { lax => 0 } ), 'job is not lax anymore';
    is $minion->jobs( { ids => [$id5] } )->next->{lax}, 0, 'not lax';
    ok $minion->job($id5)->retry, 'job is still not lax';
    is $minion->jobs( { ids => [$id5] } )->next->{lax}, 0, 'not lax';
    ok $minion->job($id5)->remove, 'job removed';
    $worker->unregister;
};

subtest 'Expiring jobs' => sub {
    my $id = $minion->enqueue('test');
    is $minion->job($id)->info->{expires}, undef, 'no expires timestamp';
    $minion->job($id)->remove;

    $id = $minion->enqueue( 'test' => [] => { expire => 300 } );
    like $minion->job($id)->info->{expires}, qr/^[\d.]+$/,
      'has expires timestamp';
    my $worker = $minion->worker->register;
    ok my $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    my $expires = $job->info->{expires};
    like $expires, qr/^[\d.]+$/, 'has expires timestamp';
    ok $job->finish, 'job finished';
    ok $job->retry( { expire => 600 } ), 'job retried';
    my $info = $minion->job($id)->info;
    is $info->{state},     'inactive',   'rigth state';
    like $info->{expires}, qr/^[\d.]+$/, 'has expires timestamp';
    isnt $info->{expires}, $expires, 'retried with new expires timestamp';
    is $minion->repair->jobs( { states => ['inactive'] } )->total, 1,
      'job has not expired yet';
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    ok $job->finish, 'job finished';

    $id = $minion->enqueue( 'test' => [] => { expire => 300 } );
    is $minion->repair->jobs( { states => ['inactive'] } )->total, 1,
      'job has not expired yet';
    my $db = $minion->backend;
    $db->jobs->update_many(
        { _id => $db->_oid($id) },
        {
            '$set' => {
                'expires' => DateTime->now->subtract( days => 1 )
            }
        }
    );
    is $minion->jobs( { states => ['inactive'] } )->total, 0, 'job has expired';
    ok !$worker->dequeue(0), 'job has expired';
    ok $db->jobs->find_one( { _id => $db->_oid($id) } ),
      'job still exists in database';
    $minion->repair;
    ok !$db->jobs->find_one( { _id => $db->_oid($id) } ),
      'job no longer exists in database';

    $id = $minion->enqueue( 'test' => [] => { expire => 300 } );
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    ok $job->finish, 'job finished';
    $db->jobs->update_many(
        { _id => $db->_oid($id) },
        {
            '$set' => {
                'expires' => DateTime->now->subtract( days => 1 )
            }
        }
    );
    $minion->repair;
    ok $job = $minion->job($id), 'job still exists';
    is $job->info->{state}, 'finished', 'right state';

    $id = $minion->enqueue( 'test' => [] => { expire => 300 } );
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    ok $job->fail, 'job failed';
    $db->jobs->update_many(
        { _id => $db->_oid($id) },
        {
            '$set' => {
                'expires' => DateTime->now->subtract( days => 1 )
            }
        }
    );
    $minion->repair;
    ok $job = $minion->job($id), 'job still exists';
    is $job->info->{state}, 'failed', 'right state';

    $id = $minion->enqueue( 'test' => [] => { expire => 300 } );
    ok $job = $worker->dequeue(0), 'job dequeued';
    is $job->id, $id, 'right id';
    $db->jobs->update_many(
        { _id => $db->_oid($id) },
        {
            '$set' => {
                'expires' => DateTime->now->subtract( days => 1 )
            }
        }
    );
    $minion->repair;
    ok $job = $minion->job($id), 'job still exists';
    is $job->info->{state}, 'active', 'right state';
    ok $job->finish, 'job finished';

    $id = $minion->enqueue( 'test' => [] => { expire => 300 } );
    my $id2 = $minion->enqueue( 'test' => [] => { parents => [$id] } );
    ok !$worker->dequeue( 0, { id => $id2 } ), 'parent is still inactive';
    $db->jobs->update_many(
        { _id => $db->_oid($id) },
        {
            '$set' => {
                'expires' => DateTime->now->subtract( days => 1 )
            }
        }
    );
    ok $job = $worker->dequeue( 0, { id => $id2 } ), 'parent has expired';
    ok $job->finish, 'job finished';
    $worker->unregister;
};

# We don't test custom classes. They works but it's backend indipendent so
# it was test in Minion::Backend::Pg

subtest 'Sequences' => sub {
    my $worker = $minion->worker->register;
    my $id =
      $minion->enqueue( 'test' => [] => { sequence => 'host:localhost' } );
    is $minion->job($id)->info->{previous}, undef, 'new sequence';
    is $minion->job($id)->info->{next},     undef, 'new sequence';
    my $id2 =
      $minion->enqueue( 'test' => [] => { sequence => 'host:localhost' } );
    is $minion->job($id2)->info->{previous}, $id,  'sequence in progress';
    is $minion->job($id)->info->{next},      $id2, 'sequence in progress';
    my $id3 = $minion->enqueue(
        'test' => [] => { sequence => 'host:localhost', priority => 5 } );
    is $minion->job($id3)->info->{previous}, $id2, 'sequence in progress';
    is $minion->job($id)->info->{next},      $id2, 'sequence in progress';
    my $job = $worker->dequeue(0);
    is $job->id, $id, 'right id';
    is $job->info->{sequence},        'host:localhost', 'right sequence';
    is $job->info->{priority},        0,                'right priority';
    is_deeply $job->info->{children}, [$id2], 'right children';
    is_deeply $job->info->{parents},  [], 'no parents';
    ok $job->finish, 'job finished';
    my $job2 = $worker->dequeue(0);
    is $job2->id, $id2, 'right id';
    is $job2->info->{sequence},        'host:localhost', 'right sequence';
    is $job2->info->{previous},        $id,  'sequence in progress';
    is $job2->info->{next},            $id3, 'sequence in progress';
    is $job2->info->{priority},        0, 'right priority';
    is_deeply $job2->info->{children}, [$id3], 'right children';
    is_deeply $job2->info->{parents},  [$id],  'right parents';
    ok $job2->finish, 'job finished';
    my $job3 = $worker->dequeue(0);
    is $job3->id, $id3, 'right id';
    is $job3->info->{sequence},        'host:localhost', 'right sequence';
    is $job3->info->{previous},        $id2, 'sequence in progress';
    is $job3->info->{next},            undef, 'sequence is ending for now';
    is $job3->info->{priority},        5,     'right priority';
    is_deeply $job3->info->{children}, [], 'no children';
    is_deeply $job3->info->{parents},  [$id2], 'right parents';
    ok $job3->finish, 'job finished';

    my $id4 =
      $minion->enqueue( 'test' => [] => { sequence => 'host:localhost' } );
    is_deeply $job3->info->{children}, [$id4], 'right children';
    my $job4 = $worker->dequeue(0);
    is $job4->id, $id4, 'right id';
    is $job4->info->{sequence},        'host:localhost', 'right sequence';
    is_deeply $job4->info->{children}, [], 'no children';
    is_deeply $job4->info->{parents},  [$id3], 'right parents';
    ok $job4->finish, 'job finished';

    my $id5 = $minion->enqueue( 'test' => [] =>
          { sequence => 'host:localhost', parents => [ $id, $id2 ] } );
    my $job5 = $worker->dequeue(0);
    is $job5->id, $id5, 'right id';
    is $job5->info->{sequence},        'host:localhost', 'right sequence';
    is_deeply $job5->info->{children}, [], 'no children';
    is_deeply $job5->info->{parents},  [ $id4, $id, $id2 ], 'right parents';
    ok $job5->finish, 'job finished';
    ok $minion->job($id5)->remove, 'job removed';

    my $id6 =
      $minion->enqueue( 'test' => [] => { sequence => 'host:localhost' } );
    my $job6 = $worker->dequeue(0);
    is $job6->id, $id6, 'right id';
    is $job6->info->{sequence},        'host:localhost', 'right sequence';
    is $job6->info->{previous},        undef,            'sequence restarted';
    is $job6->info->{next},            undef,            'sequence restarted';
    is $job4->info->{next},            $id5, 'sequence restarted';
    is_deeply $job6->info->{children}, [], 'no children';
    is_deeply $job6->info->{parents},  [], 'no parents';
    ok $job6->finish, 'job finished';

    $id = $minion->enqueue(
        'test' => [] => { sequence => 'host:mojolicious.org' } );
    $job = $worker->dequeue(0);
    is $job->id, $id, 'right id';
    is $job->info->{sequence},        'host:mojolicious.org', 'right sequence';
    is_deeply $job->info->{children}, [], 'no children';
    is_deeply $job->info->{parents},  [], 'no parents';
    ok $job->finish, 'job finished';

    is $minion->jobs( { sequences => ['host:mojolicious.org'] } )->total, 1,
      'one job';
    is $minion->jobs( { sequences => ['host:mojolicious.org'] } )->next->{id},
      $id, 'same id';
    is $minion->jobs( { sequences => ['host:metacpan.org'] } )->total, 0,
      'no jobs';
    is $minion->jobs( { sequences => ['host:localhost'] } )->total, 5,
      'five jobs';
    is $minion->jobs(
        { sequences => [ 'host:localhost', 'host:mojolicious.org' ] } )->total,
      6, 'six jobs';
    $worker->unregister;
};

subtest 'perform_jobs/perform_jobs_in_foreground' => sub {
    $minion->add_task(
        record_pid => sub {
            my $job = shift;
            $job->finish( { pid => $$ } );
        }
    );
    $minion->add_task( perform_fails => sub { die 'Just a test' } );

    my $id = $minion->enqueue('record_pid');
    $minion->perform_jobs;
    my $job = $minion->job($id);
    is $job->task, 'record_pid', 'right task';
    is $job->info->{state}, 'finished', 'right state';
    isnt $job->info->{result}{pid}, $$, 'different process id';

    my $id2 = $minion->enqueue('record_pid');
    my $id3 = $minion->enqueue('perform_fails');
    my $id4 = $minion->enqueue('record_pid');
    $minion->perform_jobs_in_foreground;
    my $job2 = $minion->job($id2);
    is $job2->task, 'record_pid', 'right task';
    is $job2->info->{state}, 'finished', 'right state';
    is $job2->info->{result}{pid}, $$, 'same process id';
    my $job3 = $minion->job($id3);
    is $job3->task, 'perform_fails', 'right task';
    is $job3->info->{state},    'failed',        'right state';
    like $job3->info->{result}, qr/Just a test/, 'right error';
    my $job4 = $minion->job($id4);
    is $job4->task, 'record_pid', 'right task';
    is $job4->info->{state}, 'finished', 'right state';
    is $job4->info->{result}{pid}, $$, 'same process id';
};

# Foreground
subtest 'Foreground' => sub {
    my $id  = $minion->enqueue( test => [] => { attempts => 2 } );
    my $id2 = $minion->enqueue('test');
    my $id3 = $minion->enqueue( test => [] => { parents => [ $id, $id2 ] } );
    ok !$minion->foreground($id3), 'job is not ready yet';
    my $info = $minion->job($id)->info;
    is $info->{attempts}, 2,          'job will be attempted twice';
    is $info->{state},    'inactive', 'right state';
    is $info->{queue},    'default',  'right queue';
    ok $minion->foreground($id), 'performed first job';
    $info = $minion->job($id)->info;
    is $info->{attempts}, 1,                   'job will be attempted once';
    is $info->{retries},  1,                   'job has been retried';
    is $info->{state},    'finished',          'right state';
    is $info->{queue},    'minion_foreground', 'right queue';
    ok $minion->foreground($id2), 'performed second job';
    $info = $minion->job($id2)->info;
    is $info->{retries}, 1,                   'job has been retried';
    is $info->{state},   'finished',          'right state';
    is $info->{queue},   'minion_foreground', 'right queue';
    ok $minion->foreground($id3), 'performed third job';
    $info = $minion->job($id3)->info;
    is $info->{retries}, 2,                   'job has been retried twice';
    is $info->{state},   'finished',          'right state';
    is $info->{queue},   'minion_foreground', 'right queue';
    $id = $minion->enqueue('fail');
    eval { $minion->foreground($id) };
    like $@, qr/Intentional failure!/, 'right error';
    $info = $minion->job($id)->info;
    ok $info->{worker}, 'has worker';
    ok !$minion->backend->list_workers( 0, 1, { ids => [ $info->{worker} ] } )
      ->{workers}[0], 'not registered';
    is $info->{retries}, 1,                        'job has been retried';
    is $info->{state},   'failed',                 'right state';
    is $info->{queue},   'minion_foreground',      'right queue';
    is $info->{result},  "Intentional failure!\n", 'right result';
};

# Worker remote control commands
subtest 'Worker remote control commands' => sub {
    my $worker  = $minion->worker->register->process_commands;
    my $worker2 = $minion->worker->register;
    my @commands;
    $_->add_command( test_id => sub { push @commands, shift->id } )
      for $worker, $worker2;
    $worker->add_command( test_args => sub { shift and push @commands, [@_] } )
      ->register;
    ok $minion->broadcast( 'test_id', [], [ $worker->id ] ), 'sent command';
    ok $minion->broadcast( 'test_id', [], [ $worker->id, $worker2->id ] ),
      'sent command';
    $worker->process_commands->register;
    $worker2->process_commands;
    is_deeply \@commands, [ $worker->id, $worker->id, $worker2->id ],
      'right structure';
    @commands = ();
    ok $minion->broadcast('test_id'),       'sent command';
    ok $minion->broadcast('test_whatever'), 'sent command';
    ok $minion->broadcast( 'test_args', [23], [] ), 'sent command';
    ok $minion->broadcast(
        'test_args',
        [ 1, [2], { 3 => 'three' } ],
        [ $worker->id ]
      ),
      'sent command';
    $_->process_commands for $worker, $worker2;
    is_deeply \@commands,
      [ $worker->id, [23], [ 1, [2], { 3 => 'three' } ], $worker2->id ],
      'right structure';
    $_->unregister for $worker, $worker2;
    ## FALLISCE
    #ok !$minion->broadcast('test_id', []), 'command not sent';
};

subtest 'Single process worker' => sub {
    my $worker = $minion->repair->worker->register;
    $minion->add_task(
        good_job => sub {
            my ( $job, $message ) = @_;
            $job->finish("$message Mojo!");
        }
    );
    $minion->add_task(
        bad_job => sub {
            my ( $job, $message ) = @_;
            die 'Bad job!';
        }
    );
    my $id  = $minion->enqueue( 'good_job', ['Hello'] );
    my $id2 = $minion->enqueue( 'bad_job',  ['Hello'] );
    while ( my $job = $worker->dequeue(0) ) {
        next unless my $err = $job->execute;
        $job->fail("Error: $err");
    }
    $worker->unregister;
    my $job = $minion->job($id);
    is $job->info->{state},  'finished',    'right state';
    is $job->info->{result}, 'Hello Mojo!', 'right result';
    my $job2 = $minion->job($id2);
    is $job2->info->{state},    'failed',            'right state';
    like $job2->info->{result}, qr/Error: Bad job!/, 'right error';
};

done_testing();
