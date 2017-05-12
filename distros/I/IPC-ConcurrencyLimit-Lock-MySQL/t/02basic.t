use strict;
use warnings;
use File::Temp;
use IPC::ConcurrencyLimit;
use IPC::ConcurrencyLimit::Lock::MySQL;
use DBI;
use DBD::mysql;
require Test::More;

$| = 1;

our($db, $usr, $pwd, $host, $port);
my $conf_file = 'mysql.dat';
if (-e $conf_file) {
  # eval connection parameters into existance
  my $ok = do $conf_file;
  defined $ok or Test::More::diag("Error loading $conf_file. Maybe you chose to skip DB-related tests: ", $@||$!);
}

if (not defined $db) {
  my $reason = 'no mysql connection details available';
  Test::More->import(skip_all => $reason);
}
else {
  Test::More->import(tests => 43);
}

my %args = (
  type => 'MySQL',
  lock_name => 'testlock',
  make_new_dbh => sub {
    my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host;port=$port", $usr, $pwd);
    $dbh or die "Could not connect to database '$db'";
    return $dbh;
  },
);

SCOPE: {
  my $limit = IPC::ConcurrencyLimit->new(%args);
  isa_ok($limit, 'IPC::ConcurrencyLimit');

  ok(!$limit->release_lock(), 'No lock to release yet');

  my $id = $limit->get_lock;
  is($id, 1, 'First and only lock has id 1');

  $id = $limit->get_lock;
  is($id, 1, 'Repeated call to lock returns same id');

  ok($limit->is_locked, 'We have a lock');
  ok($limit->lock_id, 'Lock id still 1');

  ok($limit->release_lock(), 'Lock released');
  ok(!$limit->is_locked, 'We do not have a lock');
  is($limit->lock_id, undef, 'No lock');
  
  $id = $limit->get_lock;
  is($id, 1, 'New lock returns same id');

  my $limit2 = IPC::ConcurrencyLimit->new(%args);
  my $id2 = $limit2->get_lock();
  is($id2, undef, 'Cannot get second lock');

  is($limit->release_lock(), 1, 'Lock released');
  $id2 = $limit2->get_lock();
  is($id2, 1, 'Got other lock after first was released');
}

SCOPE: {
  my $limit = IPC::ConcurrencyLimit->new(%args, max_procs => 2);
  isa_ok($limit, 'IPC::ConcurrencyLimit');

  my $id = $limit->get_lock;
  ok($id, 'Got lock');

  my $idr = $limit->get_lock;
  is($idr, $id, 'Repeated call to lock returns same id');

  my $id2;
  INNER: {
    my $limit2 = IPC::ConcurrencyLimit->new(%args, max_procs => 2);
    $id2 = $limit2->get_lock();
    ok($id2, 'Got second lock');

    ok($id != $id2, 'Lock ids are not equal');

    my $limit3 = IPC::ConcurrencyLimit->new(%args, max_procs => 2);
    my $id3 = $limit3->get_lock();
    is($id3, undef, 'Only two locks to go around');
  } # end INNER

  my $limit4 = IPC::ConcurrencyLimit->new(%args, max_procs => 2);
  my $id4 = $limit4->get_lock();
  is($id4, $id2, 'Lock 2 went out of scope, got new lock with same id');

  my $limit5 = IPC::ConcurrencyLimit->new(%args, max_procs => 2);
  my $id5 = $limit5->get_lock();
  is($id5, undef, 'Only two lock to go around');

  undef $limit;

  my $limit6 = IPC::ConcurrencyLimit->new(%args, max_procs => 2);
  my $id6 = $limit6->get_lock();
  is($id6, $id, 'Recycled first lock');
} # end SCOPE

SCOPE: {
  my $max = 20;
  my @limits = map {
    IPC::ConcurrencyLimit->new(%args, max_procs => $max)
  } (1..$max+1);

  foreach my $limitno (0..$#limits) {
    my $limit = $limits[$limitno];
    my $id = $limit->get_lock();
    if ($limitno == $#limits) {
      ok(!$id, 'One too many locks');
    }
    else {
      ok($id, 'Got lock');
    }
  }
}


