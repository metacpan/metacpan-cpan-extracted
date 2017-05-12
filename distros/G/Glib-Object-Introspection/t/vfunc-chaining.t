#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

plan tests => 34;

{
  package GoodImplementation;
  use Glib::Object::Subclass 'GI::Object';
  sub METHOD_INT8_IN {
    my ($self, $int8) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    Test::More::is ($int8, 23);
  }
  sub METHOD_INT8_OUT {
    my ($self) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    return 42;
  }
}

{
  my $foo = GoodImplementation->new;
  $foo->method_int8_in (23);
  pass;
  is ($foo->method_int8_out, 42);
  $foo->method_with_default_implementation (23);
  is ($foo->get ('int'), 23);
}

{
  package GoodChaining;
  use Glib::Object::Subclass 'GI::Object';
  sub METHOD_INT8_IN {
    my ($self, $int8) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    Test::More::is ($int8, 23);
    # cannot chain up since GI::Object does not provide a default
    # implementation
  }
  sub METHOD_INT8_OUT {
    my ($self) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    # cannot chain up since GI::Object does not provide a default
    # implementation
    return 42;
  }
  sub METHOD_WITH_DEFAULT_IMPLEMENTATION {
    my ($self, $int8) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    Test::More::is ($int8, 23);
    return $self->SUPER::METHOD_WITH_DEFAULT_IMPLEMENTATION ($int8);
  }
}

{
  my $foo = GoodChaining->new;
  $foo->method_int8_in (23);
  pass;
  $foo->method_with_default_implementation (23);
  is ($foo->get ('int'), 23);
}

{
  package PerlInheritance;
  use Glib::Object::Subclass 'GoodImplementation';
}

{
  my $foo = PerlInheritance->new;
  $foo->method_int8_in (23);
  pass;
  is ($foo->method_int8_out, 42);
  $foo->method_with_default_implementation (23);
  is ($foo->get ('int'), 23);
}

{
  package PerlInheritanceWithChaining;
  use Glib::Object::Subclass 'GoodChaining';
  sub METHOD_INT8_IN {
    my ($self, $int8) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    Test::More::is ($int8, 23);
    return $self->SUPER::METHOD_INT8_IN ($int8);
  }
  sub METHOD_INT8_OUT {
    my ($self, $int8) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    return $self->SUPER::METHOD_INT8_OUT ();
  }
  sub METHOD_WITH_DEFAULT_IMPLEMENTATION {
    my ($self, $int8) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    Test::More::is ($int8, 23);
    return $self->SUPER::METHOD_WITH_DEFAULT_IMPLEMENTATION ($int8);
  }
}

{
  my $foo = PerlInheritanceWithChaining->new;
  $foo->method_int8_in (23);
  pass;
  is ($foo->method_int8_out, 42);
  $foo->method_with_default_implementation (23);
  is ($foo->get ('int'), 23);
}

{
  package BadChaininig;
  use Glib::Object::Subclass 'GI::Object';
  sub METHOD_INT8_IN {
    my ($self, $int8) = @_;
    Test::More::isa_ok ($self, __PACKAGE__);
    Test::More::is ($int8, 23);
    return $self->SUPER::METHOD_INT8_IN ($int8);
  }
}

{
  my $foo = BadChaininig->new;
  local $@;
  eval { $foo->method_int8_in (23) };
  like ($@, qr/METHOD_INT8_IN/);
}

=for segfault

This segfaults currently because the call to method_int8_in tries to invoke the
corresponding vfunc slot in the class struct for NoImplementation.  But that's
NULL since NoImplementation doesn't provide an implementation.

{
  package NoImplementation;
  use Glib::Object::Subclass 'GI::Object';
}

{
  my $foo = NoImplementation->new;
  local $@;
  eval { $foo->method_int8_in (23) };
  like ($@, qr/method_int8_in/);
}

=cut
