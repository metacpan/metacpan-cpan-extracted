# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 34;

BEGIN { use_ok( 'EO' ); }

my $object = EO->new ();
isa_ok ($object, 'EO');

package test::Bar;

our @ISA = qw( EO );

package test::Foo;

my $init_called = 0;
our @ISA = qw(EO);

sub init {
  my $self = shift;
  $self->SUPER::init( @_ );
  $self->{ contained } = test::Bar->new();
  ++$init_called;
}

sub::Abstract 'whoot';

$object = test::Foo->new();

package main;

ok($object->oid);
isa_ok($object, 'EO');
isa_ok($object, 'test::Foo');
is($init_called, 1, 'our local init was called');
ok( my $clone = $object->clone );
ok( $clone->{ contained }, "we still have the contained object" );
ok( $clone->oid ne $object->oid, "main oids change");
ok(
   $clone->{ contained }->oid ne $object->{ contained }->oid,
   'contained oids change'
  );

eval {
  $clone->primitive;
};
ok( $@ );
isa_ok( $@, 'EO::Error' );
isa_ok( $@, 'EO::Error::Method::Private' );


$init_called = -1;
eval {
    $object = test::Foo->new();
};
isa_ok( $@, 'EO::Error');
TODO: {
    local $TODO = 'It should really be an EO object too';
    isa_ok( $@, 'EO');
}
isa_ok( $@, 'EO::Error::New', "What file the exception happend in");

like($@->file, qr/EO\.pm/);
like($@->stacktrace,qr/$0/);


eval {
    $object->baz();
};
isa_ok( $@, 'EO::Error');
TODO: {
    local $TODO = 'It should really be an EO object too';
    isa_ok( $@, 'EO');
}
isa_ok( $@, 'EO::Error::Method::NotFound', "What file the exception happend in");
isa_ok( $@, 'EO::Error::Method');

like($@->file, qr/$0/);
like($@->stacktrace,qr/$0/);


eval {
  $object->whoot();
};
ok($@);
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::Method');
isa_ok($@,'EO::Error::Method::Abstract');
is($@->text,qq{Can't call abstract method "whoot" on object of type "test::Foo"},"text check");

eval {
  test::Foo->whoot();
};
ok($@);
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::Method');
isa_ok($@,'EO::Error::Method::Abstract');
is($@->text,qq{Can't call abstract method "whoot" on object of type "test::Foo"},"text check");

