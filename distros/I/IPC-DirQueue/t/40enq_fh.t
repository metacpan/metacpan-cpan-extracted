#!/usr/bin/perl -w

use Test; BEGIN { plan tests => 81 };

use lib '../lib'; if (-d 't') { chdir 't'; }
use IPC::DirQueue;

mkdir ("log");
mkdir ("log/qdir");
my $bq = IPC::DirQueue->new({ dir => 'log/qdir' });
ok ($bq);

my $COUNT = 10;

my $tmpf = "/tmp/enqdata.$$";
open (OUT, ">$tmpf") or die "cannot write $tmpf";
print OUT "Hi There World!\n";
close OUT or die "cannot write $tmpf";

start_writer();
start_worker();
unlink $tmpf;
exit;

sub start_writer {
  for my $j (1 .. $COUNT) {
    my $counter = 0;
    open (IN, "<$tmpf") or die "cannot read $tmpf";
    ok ($bq->enqueue_fh (\*IN, { foo => "bar $$" }));
    close IN;
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

    ok ($str =~ /^Hi There World!$/)   
        or warn "got: [$str]";
        
    # With get_data()
    my $data = $job->get_data();
    ok ($data =~ /^Hi There World!$/)   
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

