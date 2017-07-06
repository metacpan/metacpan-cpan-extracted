use Mojo::Base -strict;
use Test::More;

use Minion;
use Time::HiRes 'time';

my $DEQUEUE     = 2;
my $REPETITIONS = 2;
my $WORKERS     = 2;
my $ENQUEUE     = $DEQUEUE * $REPETITIONS * $WORKERS;
my $STATS       = 1;
my $REPAIR      = 1;
my $INFO        = 1;

my $minion = Minion->new(Storable => '/tmp/minion.data');
$minion->add_task(foo => sub { });
$minion->add_task(bar => sub { });
$minion->reset;

$minion->enqueue($_ % 2 ? 'foo' : 'bar') for 1 .. $ENQUEUE;

diag sprintf 'Parent PID: %u', $$;

sub dequeue {
  my @pids;
  for (1 .. $WORKERS) {
    die "Couldn't fork: $!" unless defined(my $pid = fork);
    unless ($pid) {
      my $worker = $minion->worker->register;
      for (1 .. $DEQUEUE) {
        my $job = $worker->dequeue(0);
        ok $job, sprintf 'I (%u) got job: %s', $$, $job->{id};
        $job->finish;
      }
      $worker->unregister;
      exit;
    }
    push @pids, $pid;
  }

  waitpid $_, 0 for @pids;
}
dequeue() for 1 .. $REPETITIONS;
my $stats = $minion->stats;
is $stats->{inactive_jobs}, 0, 'No jobs inactive';
is $stats->{finished_jobs}, $ENQUEUE, 'All jobs finished';

done_testing();
