use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type

=abstract

Data-Object Type Constraint Builder

=synopsis

  package App::Type::Id;

  use parent 'Data::Object::Type';

  sub name {
    return 'Id';
  }

  sub parent {
    return 'Str';
  }

  sub namespace {
    return 'App::Type::Library';
  }

  sub validation {
    my ($self, $data) = @_;

    return 0 if !$data;

    return 0 if $data !~ /^\d+$/;

    return 1;
  }

=description

This package is an abstract base class for type constraint builder classes.
This package inherits all behavior from L<Data::Object::Base>.

=cut

use_ok "Data::Object::Type";

ok 1 and done_testing;
