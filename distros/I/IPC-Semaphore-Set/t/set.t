use Test::More tests => 15;

BEGIN { use_ok( 'IPC::Semaphore::Set' ) }

# new

my $semset_with_key = IPC::Semaphore::Set->new(
	key => 1337,
);
is($semset_with_key->key, 1337, 'key was as 1337 as expected');
is($semset_with_key->remove, 1, 'successfully removed semaphore set');

my $semset = IPC::Semaphore::Set->new(
	key_name  => 'IPC::Semaphore::Set Tests Basics',
	resources => 3,
	value     => 2,
);
isa_ok($semset, 'IPC::Semaphore::Set');

# resources

my @resources = $semset->resources;
is(scalar(@resources), 3, 'got [3] resources');

foreach my $resource (@resources) {
	isa_ok($resource, 'IPC::Semaphore::Set::Resource');
	is($resource->value, 2, 'resource had [2] value');
}

my $resource0 = $semset->resource;
is($resource0->number, 0, 'got the default first [0] resource');

my $resource1 = $semset->resource(number => 2);
is($resource1->number, 2, 'got a proper resource by number');

my $resource2 = $semset->resource;
is($resource2->number, 0, 'got the expected stored resource');
is($semset->remove, 1, 'successfully removed semaphore set');
