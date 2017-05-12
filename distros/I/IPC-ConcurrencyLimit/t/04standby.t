use strict;
use warnings;
use File::Temp;
use File::Path qw(mkpath);
use File::Spec;
use IPC::ConcurrencyLimit::WithStandby;

use Test::More;
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

use Test::More tests => 6;

# TMPDIR will hopefully put it in the logical equivalent of
# a /tmp. That is important because no sane admin will mount /tmp
# via NFS and we don't want to fail tests just because we're being
# built/tested on an NFS share.
my $tmpdir = File::Temp::tempdir( CLEANUP => 1, TMPDIR => 1 );
my $standby = File::Spec->catdir($tmpdir, 'standby');
mkpath($standby);

my %shared_opt = (
  path => $tmpdir,
  standby_path => $standby,
  max_procs => 1,
  lock_mode => 'exclusive',
  interval => 0.5,
  retries => 10,
);

SCOPE: {
  my $limit = IPC::ConcurrencyLimit::WithStandby->new(%shared_opt);
  isa_ok($limit, 'IPC::ConcurrencyLimit::WithStandby');

  my $id = $limit->get_lock;
  ok($id, 'Got lock');

  my $limit2 = IPC::ConcurrencyLimit::WithStandby->new(%shared_opt);
  my $idr;
  SCOPE: {
    local $limit2->{interval} = 0;
    $idr = $limit2->get_lock;
    ok(not defined $idr);
  }

  my $pid = fork();
  if ($pid) {
    $limit->release_lock;
    $idr = $limit2->get_lock;
    ok(defined $idr, "Got lock after retrying 2 secs");
  }
  else {
    sleep 2;
    $limit->release_lock;
    exit;
  }
  waitpid($pid, 0);
}

SCOPE: {

    my %shared_opt_2 = (
        %shared_opt,
        max_procs         => 1,
        standby_max_procs => 1,
        interval          => .01,
        retries           => sub {1},
    );
    my $pid = fork();
    if ($pid) {
        my $limit = IPC::ConcurrencyLimit::WithStandby->new(%shared_opt_2);
        my $idr   = $limit->get_lock;
        sleep 3;
        $limit->release_lock;
        Test::More->builder->no_ending(1);
        waitpid( $pid, 0 );
    }
    else {
        my $when = Time::HiRes::time;
        Time::HiRes::sleep .1;
        my $limit = IPC::ConcurrencyLimit::WithStandby->new(%shared_opt_2);
        my $idr   = $limit->get_lock;
        my $when2 = Time::HiRes::time;
        ok( defined $idr, 'Got 2nd lock after infinite retry (.01 s interval)' );
        ok( ( $when2 - $when >= 3 && $when2 - $when <= 4 ),
            'We actually waited about 3s as expected'
        );
        exit 0;
    }
}

File::Path::rmtree($tmpdir);
