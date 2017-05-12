# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More no_plan => 1;

ok(my $object = MyThing->new());
ok(!$object->can('hello'), 'no method hello in object');
ok($object->hello(),'the hello method was delegated fine...');
ok(!$object->wah(), "shouldn't work");
if ($@) {
  isa_ok($@,'EO::Error::Method::NotFound');
  isa_ok($@,'EO::Error');
}

package MyThing;

use strict;
use warnings;

use EO;
use base qw( EO );
use EO::delegate;

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->delegate( bless({},'Foo') );
    $self->delegate_error('record');
    return 1;
  }
  return 0;
}

package Foo;

sub hello {
  main::ok(1, "delegate passed on");
}

1;



