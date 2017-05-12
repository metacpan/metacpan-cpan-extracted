#!/usr/bin/perl -w
#
# This test starts off with several very full queues; as the
# test continues, eventually the queues are exhausted and the
# qprocs are left idle, waiting for enqueued data.

use constant SKIP => ($^O =~ /^(mswin|dos|os2)/oi);

use Test; BEGIN { plan tests => SKIP ? 0 : 18 };
exit if SKIP;

use lib '../lib'; if (-d 't') { chdir 't'; }
use IPC::DirQueue;

system ("rm -rf log/qdir");
mkdir ("log");
mkdir ("log/qdir");
my $bq = IPC::DirQueue->new({
    dir => 'log/qdir', ordered => 0
  });
ok ($bq);

unlink ("log/counter");
$| = 1;

my @pids = ();

for my $i (0 .. 4) {
  my $pid = fork();
  if ($pid) {
    push (@pids, $pid);
    ok (1);
  }
  else {
    start_writer();
    exit;
  }
}
sleep 4;

for my $i (0 .. 4) {
  my $pid = fork();
  if ($pid) {
    push (@pids, $pid);
    ok (1);
  }
  else {
    start_worker();
    exit;
  }
}
sleep 4;

for my $i (0 .. 300) {
  sleep 1;
  my $count = (-s "log/counter");
  if (!defined $count) {
    warn "log/counter disappeared: $@ $!";
    system ("ls -l log/counter");
    die;
  }
  print "count: $count at $i     in qdir: ".count_qdir()."\n";
  if ($count && $count == 500) {
    last;
  }
}

ok (1);
kill (15, @pids);

for my $i (0 .. 4) {
  waitpid ($pids[$i], 0) or die "waitpid failed";
  ok (1);
}

my $left_in_qdir = count_qdir();
ok ($left_in_qdir == 0) or system("ls -l log/qdir/queue");
exit;

use Time::HiRes qw(sleep);

sub start_worker {
  my $k = 0;
  print "worker $$: forked\n";
  while (1) {
    my $job = $bq->wait_for_queued_job();
    if (!$job) { next; }
    $k++;

    print "starting $k in $$: data: ".$job->get_data_path()."\n";

    if ($k > 60) {
      sleep 0.1;
    } else {
      sleep 0.3;
    }

    open (COUNT, ">>log/counter"); print COUNT "."; close COUNT;
    $job->finish();
    # print "finished $k in $$\n";
  }
}

sub start_writer {
  for my $j (1 .. 100) {
    $bq->enqueue_string ("hello world! $$", { foo => "bar $$" });

    my $delay = (0.01 + ($j * 0.01));
    # print "writer sleeping $delay in $$\n";
    sleep $delay;
  }
}

sub count_qdir {
  opendir (DIR, "log/qdir/queue");
  my @count = grep { !/^\.\.?$/ } readdir(DIR);
  closedir DIR;
  return scalar @count;
}


