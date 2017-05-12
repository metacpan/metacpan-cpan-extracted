use Test::More no_plan => 1;

BEGIN { use_ok( 'EO::Singleton' ); }

my $object = EO::Singleton->new ();
isa_ok ($object, 'EO::Singleton');

package test::Foo;
our @ISA = qw(EO::Singleton);

package test::Frob;
our @ISA = qw(EO::Singleton);

package main;

$object_1 = test::Foo->new();
$object_2 = test::Foo->new();
$object_3 = test::Frob->new();
$object_4 = test::Frob->new();
isa_ok($object_1, 'EO::Singleton');
isa_ok($object_1, 'test::Foo');
isa_ok($object_3, 'EO::Singleton');
isa_ok($object_3, 'test::Frob');
isa_ok($object_4, 'EO::Singleton');
isa_ok($object_4, 'test::Frob');

is($object_3, $object_4, "two different objects are actually the same");
is($object_1, $object_2, "two different objects are actually the same");
ok($object_1 != $object_3, "singletons don't span classes");
is($object_1->clone, $object_1, "cloned singleton is the same object");
