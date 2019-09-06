use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Immutable

=abstract

Data-Object Immutability Role

=synopsis


  use Data::Object::Class;
  use Data::Object::Signatures;

  with 'Data::Object::Role::Immutable';

  method BUILD($args) {
    $self->immutable;

    return $args;
  }

=libraries

Data::Object::Library

=description

This package provides a mechanism for making any derived object immutable.

=cut

use_ok "Data::Object::Role::Immutable";

ok 1 and done_testing;
