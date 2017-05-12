use Test::More tests => 11;

BEGIN { use_ok( 'IPC::Semaphore::Set' ) }

# basic locking, checking

{
	my $semset = IPC::Semaphore::Set->new(
		key_name  => 'IPC::Semaphore::Set Testing stuff!lolz',
		resources => 3,
		value     => 1,
	);
	isa_ok($semset, 'IPC::Semaphore::Set');
	my $resource = $semset->resource(cleanup_object => 0);
	is($resource->lock,  1, 'able to get a lock');
	is($resource->value, 0, 'reduced value by 1');
}

# verify the previous locking is working, and that the changes persist

{
	my $semset = IPC::Semaphore::Set->new(
		key_name  => 'IPC::Semaphore::Set Testing stuff!lolz',
	);
	isa_ok($semset, 'IPC::Semaphore::Set');
	my $resource = $semset->resource(cleanup_object => 0);
	isa_ok($resource, 'IPC::Semaphore::Set::Resource');
	is($resource->lock,  0, 'unable to get a lock');
	is($resource->value, 0, 'value was 0 as expected with destructor disabled');
	is($resource->addValue, 1, 'able to add value back to the resource');
}

# double check that we have the right resource value after previous tests

{
	my $semset = IPC::Semaphore::Set->new(
		key_name  => 'IPC::Semaphore::Set Testing stuff!lolz',
	);
	isa_ok($semset, 'IPC::Semaphore::Set');
	is($semset->resource->value, 1, 'resource value remains properly updated back to 1');
}
