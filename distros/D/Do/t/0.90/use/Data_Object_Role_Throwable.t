use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Throwable

=abstract

Data-Object Throwable Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Throwable';

=libraries

Data::Object::Library

=description

This package provides mechanisms for throwing the object as an exception.

=cut

use_ok "Data::Object::Role::Throwable";

ok 1 and done_testing;
