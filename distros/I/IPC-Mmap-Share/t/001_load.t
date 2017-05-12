# -*- perl -*-

# t/001_load.t - check module loading and create testing directory


use Test::More tests => 5;

BEGIN { use_ok( 'IPC::Mmap::Share' ); }

my $object = IPC::Mmap::Share->new(100);

isa_ok ($object, 'IPC::Mmap::Share');

my $data = 135;

$object->set($data);

cmp_ok($data, '==', $object->get, "Store and retrieve");

$object->lock();
$object->unlock();

pass("Explicit lock and unlock");

$object->DESTROY;

pass("Explicit destroy");




