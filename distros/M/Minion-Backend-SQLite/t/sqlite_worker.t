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
