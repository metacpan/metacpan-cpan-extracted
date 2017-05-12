#!/usr/bin/perl -w

use Test; BEGIN { plan tests => 801 };

use lib '../lib'; if (-d 't') { chdir 't'; }
use IPC::DirQueue;

mkdir ("log");
mkdir ("log/qdir");
my $bq = IPC::DirQueue->new({
            dir => 'log/qdir',
            use_queue_fanout => 1
        });
ok ($bq);

my $COUNT = 100;

start_writer();
start_worker();
exit;

sub start_writer {
  for my $j (1 .. $COUNT) {
    ok ($bq->enqueue_string ("hello world! $$", { foo => "bar $$" }));
  }
}

sub start_worker {
  my $k = 0;
  while (1) {
    my $job = $bq->wait_for_queued_job();
    if (!$job) { next; }

    # Traditional
    ok ($job->get_data_path());
    ok (open (IN, "<".$job->get_data_path()));
    my $str = <IN>;
    ok (close IN);

    ok ($str =~ /^hello world! \d+$/)   
        or warn "got: [$str]";
        
    # With get_data()
    my $data = $job->get_data();
    ok ($data =~ /^hello world! \d+$/)   
        or warn "got: [$data]";

    ok ($job->{metadata}->{foo});
    ok ($job->{metadata}->{foo} =~ /^bar \d+$/)
        or warn "got: [$job->{metadata}->{foo}]";

    $job->finish();
    $k++;
    print "finished $k\n";
    exit if ($k == $COUNT);
  }
}

