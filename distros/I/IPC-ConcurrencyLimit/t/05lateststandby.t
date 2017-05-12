use strict;
use warnings;
use File::Temp;
use File::Path qw(mkpath);
use File::Spec;
use IPC::ConcurrencyLimit::WithLatestStandby;
use POSIX ":sys_wait_h";
use Test::More;
use Time::HiRes qw(time sleep);
BEGIN {
  if ($^O !~ /linux/i && $^O !~ /win32/i && $^O !~ /darwin/i) {
    Test::More->import(
      skip_all => <<'SKIP_MSG',
Will test the fork-using tests only on linux, win32, darwin since I probably
don't understand other OS well enough to fiddle this test to work
SKIP_MSG
    );
    exit(0);
  }
}

use Test::More tests => 11;

# TMPDIR will hopefully put it in the logical equivalent of
# a /tmp. That is important because no sane admin will mount /tmp
# via NFS and we don't want to fail tests just because we're being
# built/tested on an NFS share.
my $tmpdir = File::Temp::tempdir( CLEANUP => 1, TMPDIR => 1 );
my $standby = File::Spec->catdir($tmpdir, 'latest-standby');
mkpath($standby);

my $debug = 0;
my $out_file="$tmpdir/out.txt";
sub _print {
    open my $out_fh, ">>", $out_file
        or die "failed to write outfile '$out_file':$!";
    my $msg=join "", @_;
    $msg=~s/\n?\z/\n/;
    print $out_fh $msg;
    close $out_fh;
    diag $msg
        if $debug;
};
my %shared_opt = (
  path => $tmpdir,
  poll_time => 0.1,
  debug_sub => sub { _print( "pid: $$: ", @_) },
  debug => 1,
);

SCOPE: {
    my $limit = IPC::ConcurrencyLimit::WithLatestStandby->new(%shared_opt);
    isa_ok($limit, 'IPC::ConcurrencyLimit::WithLatestStandby');

    my $id = $limit->get_lock;
    ok($id, 'Got lock');

    my $max_id= 0;
    my $child_process= sub {
        my $sleep_after_secs= shift || 0.5;
        my $sleep_lock_secs= shift || 0;
        my $id= ++$max_id;
        my $pid= fork() // die "Failed to fork!";
        if (!$pid) {
            # child process
            $limit = IPC::ConcurrencyLimit::WithLatestStandby->new(%shared_opt);
            if ($limit->get_lock) {
                _print("pid: success! got lock $id. (sleeping for $sleep_lock_secs)");
                sleep($sleep_lock_secs) if $sleep_lock_secs;
            } else {
                _print("pid: no lock $id");
            }
            exit(0);
        } else {
            _print("Started $id as $pid (sleeping for $sleep_after_secs)\n");
            sleep($sleep_after_secs) if $sleep_after_secs;
            return $pid;
        }
    };

    my $worker= $child_process->();
    is(waitpid($worker,WNOHANG),0,"first worker running");
   
    for (1..3) {
        my $new_worker= $child_process->(0.5,2);
        is(waitpid($new_worker,WNOHANG), 0, "new worker running");
        is(waitpid($worker,WNOHANG), $worker, "old worker stopped")
            or die "Stopping...\n";
        $worker= $new_worker;
    }

    $limit->release_lock();
    diag "sleeping after releasing master lock" if $debug;
    sleep(3); 
    is(waitpid($worker,WNOHANG), $worker, "last worker exited after master release_lock");

    my @pids;
    diag "starting 1..30 loop" if $debug;

    for (1..30) {
        my $pid= $child_process->(0.5,2)
            or next;
        push @pids, $pid;
        @pids= grep { 
            my $wait_res= waitpid($worker,WNOHANG);
            if (!$wait_res) {
                _print "pid: $_: exited";
            }
            !$wait_res;
        } @pids;
    }

    while (@pids) {
        @pids= grep { 
            !waitpid($worker,WNOHANG)
        } @pids;
    }

    my $ok=1;
    my $last= 0;
    open my $fh, "<", $out_file
        or die "cant read out_file '$out_file': $!";
    while (<$fh>) {
        if ( /success! got lock (\d+)/ ) {
            $ok=0 unless $1 > $last;
            $last= $1;
        }
    }
    close $fh;
    ok($ok,"We got the expected sequence of worker ids");
}

__END__
