use Test::More tests => 17;

BEGIN { use_ok( 'IPC::Semaphore::Set' ) }

# lockOrDie

my $semset = IPC::Semaphore::Set->new(
	key_name  => 'IPC::Semaphore::Set Tests',
	resources => 10,
	value     => 3,
);
isa_ok($semset, 'IPC::Semaphore::Set');

my $lockOrDie = eval{$semset->resource->lockOrDie};
is($lockOrDie, 1, 'able to lock once');

# lockWait, when we expect that we can, and when we can't lock

eval {
	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm 3;
	$lockWait = $semset->resource->lockWait;
	alarm 0;
};
is($lockWait, 1, 'able to lock a second time');

is($semset->resource->lock, 1, 'able to lock a third time');
is($semset->resource->lock, 0, 'unable to lock a fourth time');

my $lockWait;
eval {
	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm 1;
	$lockWait = $semset->resource->lockWait;
	alarm 0;
};
my $alarm = ($@ eq "alarm\n");
is($alarm, 1, 'alarm reached properly after one second');
is($lockWait, undef, 'received no response from lock');

# lockOrDie

eval{$semset->resource->lockOrDie};
my $error = ($@ =~ m/could not lock on semaphore/);
is($error, 1, 'died trying to get an unavailable resource');

# lockWaitTimeoutDie

eval{$semset->resource->lockWaitTimeoutDie(1)};
$error = ($@ =~ m/could not establish lock after 1 seconds/);
is($error, 1, 'died waiting for lock');

# test some final resource value changing

is($semset->resource->addValue, 1, 'able to add value');
is($semset->resource->lockWaitTimeout, 1, 'able to lock with wait');
is($semset->resource->addValue, 1, 'able to add value');
is($semset->resource->addValue, 1, 'able to add value twice');
is($semset->resource->addValue, 1, 'able to add value a third time');
is($semset->resource->value, 3, 'correct availability found in semaphore resource');

# remove

is($semset->remove, 1, 'successfully removed semaphore set');
