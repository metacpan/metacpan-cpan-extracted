use strict;
use warnings;
use Test::More;
use IPC::ConcurrencyLimit;
use IPC::ConcurrencyLimit::Lock::Redis;
use Redis;

if (not -f 'redis_connect_data') {
  plan(skip_all => "Need Redis test server host:port in the 'redis_connect_data' file");
  exit(0);
}

open my $fh, "<", "redis_connect_data" or die $!;
my $host = <$fh>;
close $fh;
$host =~ s/^\s+//;
chomp $host;
$host =~ s/\s+$//;

my $conn;
eval { $conn = Redis->new(server => $host); 1 }
or do {
  my $err = $@ || 'Zombie error';
  diag("Failed to connect to Redis server: $err. Not running tests");
  plan(skip_all => "Cannot connect to Redis server");
  exit(0);
};

eval {
  $conn->script_load("return 1");
  1
} or do {
  my $err = $@ || 'Zombie error';
  diag("Redis server does not appear to support Lua scripting. Not running tests");
  plan(skip_all => "Redis server does not support Lua scripting");
  exit(0);
};

my %args = (
  redis_conn => $conn,
  proc_info => "foo",
  type => 'Redis',
  key_name => 'mylock',
);

$conn->del($args{key_name});

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

  ok($limit->heartbeat, 'Lock alive');

  SCOPE: {
    my $_lock = $limit->{lock_obj}; # breaking encapsulation
    is($conn->hget($_lock->key_name, $_lock->id),
       $_lock->uuid . "-" . $_lock->proc_info,
       "UUID/procinfo ok");
  }

  is($limit->release_lock(), 1, 'Lock released');
  ok(!$limit->heartbeat, 'Lock not alive');

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

# Nasty clear_old_locks test
SCOPE: {
  my $limit = IPC::ConcurrencyLimit->new(%args);
  isa_ok($limit, 'IPC::ConcurrencyLimit');

  my $id = $limit->get_lock;
  is($id, 1, 'First and only lock has id 1');

  my $lock = $limit->{lock_obj};
  $lock->{id} = 0; # mwuahah
  my $conn = $lock->redis_conn;
  my $n = IPC::ConcurrencyLimit::Lock::Redis->clear_old_locks($conn, $args{key_name}, 0);
  is($n, 0);

  $n = IPC::ConcurrencyLimit::Lock::Redis->clear_old_locks($conn, $args{key_name}, time+1);
  is($n, 1);
}

done_testing;

