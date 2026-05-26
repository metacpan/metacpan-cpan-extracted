use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;

use Config;
use Minion;

plan skip_all => 'Minion workers do not support fork emulation' if $Config{d_pseudofork};

my $minion = Minion->new('SQLite');

subtest 'Basics' => sub {
  $minion->add_task(
    test => sub {
      my $job = shift;
      $job->finish({just => 'works!'});
    }
  );
  my $worker = $minion->worker;
  $worker->on(
    dequeue => sub {
      my ($worker, $job) = @_;
      $job->on(reap => sub { kill 'INT', $$ });
    }
  );
  my $id = $minion->enqueue('test');
  my $max;
  $worker->once(wait => sub { $max = shift->status->{jobs} });
  $worker->run;
  is $max, 4, 'right value';
  is_deeply $minion->job($id)->info->{result}, {just => 'works!'}, 'right result';
};

subtest 'Dispatch schedules' => sub {
  my $sid = $minion->schedule(due_now => '0 4 * * *' => 'test');
  $minion->backend->sqlite->db->query(q{update minion_schedules set next_run = datetime('now', '-1 minutes') where id = ?},
    $sid);

  my $worker = $minion->worker;
  $worker->status->{dequeue_timeout} = 0;
  $worker->on(
    dequeue => sub {
      my ($worker, $job) = @_;
      $job->on(reap => sub { kill 'INT', $$ });
    }
  );
  $worker->run;

  my $info = $minion->list_schedules(0, 10, {ids => [$sid]})->{schedules}[0];
  ok $info->{last_job}, 'schedule fired';
  is_deeply $minion->job($info->{last_job})->info->{result}, {just => 'works!'}, 'right result';

  $minion->unschedule('due_now');
};

subtest 'Task limit' => sub {
  $minion->add_task(
    $_ => sub {
      my $job = shift;
      $job->finish({just => 'works!'});
    }
  ) for qw(foo bar baz);
  my $worker = $minion->worker;
  $worker->status->{dequeue_timeout} = 0;
  $worker->status->{limits}          = {foo => 0};
  $worker->status->{jobs}            = 1;
  $worker->on(
    dequeue => sub {
      my ($worker, $job) = @_;
      return unless $job->task eq 'baz';
      $job->on(reap => sub { kill 'INT', $$ });
    }
  );
  my $id  = $minion->enqueue('foo');
  my $id2 = $minion->enqueue('bar');
  my $id3 = $minion->enqueue('baz');
  $worker->run;
  is_deeply $minion->job($id)->info->{state},  'inactive', 'right state';
  is_deeply $minion->job($id2)->info->{state}, 'finished', 'right state';
  is_deeply $minion->job($id3)->info->{state}, 'finished', 'right state';
};

subtest 'Clean up event loop' => sub {
  my $timer = 0;
  Mojo::IOLoop->recurring(0 => sub { $timer++ });
  my $worker = $minion->worker;
  $worker->status->{dequeue_timeout} = 0;
  $worker->on(
    dequeue => sub {
      my ($worker, $job) = @_;
      $job->on(reap => sub { kill 'INT', $$ });
    }
  );
  my $id = $minion->enqueue('test');
  $worker->run;
  is_deeply $minion->job($id)->info->{result}, {just => 'works!'}, 'right result';
  is $timer, 0, 'timer has been cleaned up';
};

subtest 'Signals' => sub {
  $minion->add_task(
    int => sub {
      my $job     = shift;
      my $forever = 1;
      my %received;
      local $SIG{INT}  = sub { $forever = 0 };
      local $SIG{USR1} = sub { $received{usr1}++ };
      local $SIG{USR2} = sub { $received{usr2}++ };
      $job->minion->broadcast('kill', [$_, $job->id]) for qw(USR1 USR2 INT);
      while ($forever) { sleep 1 }
      $job->finish({msg => 'signals: ' . join(' ', sort keys %received)});
    }
  );
  my $worker = $minion->worker;
  $worker->status->{command_interval} = 1;
  $worker->on(
    dequeue => sub {
      my ($worker, $job) = @_;
      $job->on(reap => sub { kill 'INT', $$ });
    }
  );
  my $id = $minion->enqueue('int');
  $worker->run;
  is_deeply $minion->job($id)->info->{result}, {msg => 'signals: usr1 usr2'}, 'right result';

  my $status = $worker->status;
  is $status->{command_interval},   1,   'right value';
  is $status->{dequeue_timeout},    5,   'right value';
  is $status->{heartbeat_interval}, 300, 'right value';
  is $status->{jobs},               4,   'right value';
  is_deeply $status->{queues}, ['default'], 'right structure';
  is $status->{performed}, 1, 'right value';
  ok $status->{repair_interval}, 'has a value';
};

$minion->reset({all => 1});

done_testing();
