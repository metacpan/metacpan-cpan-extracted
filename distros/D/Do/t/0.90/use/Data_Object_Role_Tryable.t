use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Tryable

=abstract

Data-Object Tryable Role

=synopsis

  use Data::Object::Class;

  use Data::Object::Role::Tryable;

  my $try = $self->try($method);

  $try->catch($type, fun ($caught) {
    # caught an exception

    return $something;
  });

  $try->default(fun ($caught) {
    # catch the uncaught

    return $something;
  });

  $try->finally(fun ($self, $caught) {
    # always run after try/catch
  });

  my $result = $try->result;

=libraries

Data::Object::Library

=description

This role provides a wrapper around the L<Data::Object::Try> class which
provides an object-oriented interface for performing complex try/catch
operations.

=cut

use_ok "Data::Object::Role::Tryable";

ok 1 and done_testing;
