#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

eval {
  testOid->new();
};
ok($@);
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::Method');
isa_ok($@,'EO::Error::Method::Private');
ok(my $foo = testOid->new());
eval {
  $foo->primitive;
};
ok($@);
isa_ok($@,'EO::Error');
isa_ok($@,'EO::Error::Method');
isa_ok($@,'EO::Error::Method::Private');


package testOid;

use EO;
use base qw( EO );

$testOid::init = 0;

sub init {
  my $self = shift;
  if (!$testOid::init) {
    $testOid::init = 1;
    $self->set_oid( '134e124124' );
  } else {
    if ($self->SUPER::init( @_ )) {
      return 1;
    }
  }
  return 0;
}

1;

