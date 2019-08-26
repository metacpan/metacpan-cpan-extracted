use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Signatures

=abstract

Data-Object Signatures Configuration

=synopsis

  use Data::Object::Signatures;

  fun hello (Str $name) {
    return "Hello $name, how are you?";
  }

  around created() {
    # do something ...
    return $self->$orig;
  }

  around updated() {
    # do something ...
    return $self->$orig;
  }

=description

This package is provides method and function signatures supporting all the type
constraints provided by L<Data::Object::Library>.

=cut

use_ok "Data::Object::Signatures";

ok 1 and done_testing;
