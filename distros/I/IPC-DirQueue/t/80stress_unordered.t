#!/usr/bin/perl -w

use constant SKIP => ($^O =~ /^(mswin|dos|os2)/oi);

use Test; BEGIN { plan tests => SKIP ? 0 : 113 };
exit if SKIP;

use lib '../lib'; if (-d 't') { chdir 't'; }
use IPC::DirQueue;

mkdir ("log");
mkdir ("log/qdir");
my $bq = IPC::DirQueue->new({ dir => 'log/qdir', ordered => 0 });
ok ($bq);

unlink ("log/counter");

my @pids = ();
for my $i (0 .. 4) {
  my $pid = fork();
  if ($pid) {
    push (@pids, $pid);
    ok (1);
  }
  else {
    start_worker();
  }
}
start_writer();

for my $i (0 .. 60) {
  sleep 1;
  my $count = (-s "log/counter");
  if ($count && $count >= 100) {
    last;
  }
  print "count: $count\n";
}

ok (1);
kill (15, @pids);

for my $i (0 .. 4) {
  waitpid ($pids[$i], 0) or die "waitpid failed";
  ok (1);
}
ok (1);
exit;

use Time::HiRes qw(sleep);

sub start_worker {
  my $k = 0;
  while (1) {
    my $job = $bq->wait_for_queued_job();
    if (!$job) { next; }
    $k++;

    print "starting $k in $$: data: ".$job->get_data_path()."\n";
    sleep 0.1;
    open (COUNT, ">>log/counter"); print COUNT "."; close COUNT;
    $job->finish();
    print "finished $k in $$\n";
  }
}

sub start_writer {
  for my $j (1 .. 100) {
    ok ($bq->enqueue_string ("hello world! $$", { foo => "bar $$" }));
    sleep 0.05;
  }
}

