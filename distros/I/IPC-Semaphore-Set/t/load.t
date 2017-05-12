use Test::More tests => 5;

BEGIN { use_ok( 'IPC::Semaphore::Set' ) }

my $semset = IPC::Semaphore::Set->new();
isa_ok($semset, 'IPC::Semaphore::Set');

my $semaphore = $semset->semaphore;
isa_ok($semaphore, 'IPC::Semaphore');

my $resource = $semset->resource;
isa_ok($resource, 'IPC::Semaphore::Set::Resource');
is($semset->remove, 1, 'successfully removed semaphore set');
