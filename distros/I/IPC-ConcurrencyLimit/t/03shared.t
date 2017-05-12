use strict;
use warnings;
use File::Temp;
use Test::More tests => 12;
use IPC::ConcurrencyLimit;

# TMPDIR will hopefully put it in the logical equivalent of
# a /tmp. That is important because no sane admin will mount /tmp
# via NFS and we don't want to fail tests just because we're being
# built/tested on an NFS share.
my $tmpdir = File::Temp::tempdir( CLEANUP => 1, TMPDIR => 1 );

my @shared_opt = (
  path => $tmpdir,
  max_procs => 1,
  lock_mode => 'shared',
);
my @exclusive_opt = (
  path => $tmpdir,
  max_procs => 1,
  lock_mode => 'exclusive',
);

SCOPE: {
  my $limit = IPC::ConcurrencyLimit->new(@shared_opt);
  isa_ok($limit, 'IPC::ConcurrencyLimit');

  my $id = $limit->get_lock;
  ok($id, 'Got lock');

  my $idr = $limit->get_lock;
  is($idr, $id, 'Repeated call to lock returns same id');

  my $limit2 = IPC::ConcurrencyLimit->new(@shared_opt);
  my $id2 = $limit2->get_lock();
  ok($id2, 'Got second lock');
  is($id2, $id, 'Lock ids are equal');

  INNER: {
    my $limit3 = IPC::ConcurrencyLimit->new(@shared_opt);
    my $id3 = $limit3->get_lock();
    is($id3, $id, 'Lock ids are equal') or diag("id=$id, id3=$id3");

    my $exlimit = IPC::ConcurrencyLimit->new(@exclusive_opt);
    my $exid = $exlimit->get_lock();
    ok(!defined($exid), "Could not get exclusive lock") or diag("id=$id exid=$exid");
  } # end INNER

  my $exlimit = IPC::ConcurrencyLimit->new(@exclusive_opt);
  my $exid = $exlimit->get_lock();
  ok(!defined($exid), "Could not get exclusive lock");
}

SCOPE: {
  my $limit = IPC::ConcurrencyLimit->new(@exclusive_opt);
  isa_ok($limit, 'IPC::ConcurrencyLimit');

  my $id = $limit->get_lock;
  ok($id, 'Got lock');

  my $limit2 = IPC::ConcurrencyLimit->new(@shared_opt);
  my $id2 = $limit2->get_lock();
  ok(!defined($id2), "Could not get shared lock on exclusively locked item");

  my $limit3 = IPC::ConcurrencyLimit->new(@exclusive_opt);
  my $id3 = $limit3->get_lock();
  ok(!defined($id3), "Could not get ex lock on exclusively locked item");
}


