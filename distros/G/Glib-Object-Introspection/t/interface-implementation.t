#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

plan tests => 7;

{
  package NoImplementation;
  use Glib::Object::Subclass
    'Glib::Object',
    interfaces => [ 'GI::Interface' ];
}

{
  my $foo = NoImplementation->new;
  local $@;
  eval { $foo->test_int8_in (23) };
  like ($@, qr/TEST_INT8_IN/);
}

{
  package GoodImplementation;
  use Glib::Object::Subclass
    'Glib::Object',
    interfaces => [ 'GI::Interface' ];
  sub TEST_INT8_IN {
    my ($self, $int8) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    Test::More::isa_ok ($self, 'GI::Interface');
  }
}

{
  my $foo = GoodImplementation->new;
  $foo->test_int8_in (23);
  pass;
}

{
  package InheritedImplementation;
  use Glib::Object::Subclass 'GoodImplementation';
}

{
  my $foo = InheritedImplementation->new;
  $foo->test_int8_in (23);
  pass;
}
