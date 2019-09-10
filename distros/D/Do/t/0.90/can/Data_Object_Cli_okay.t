use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

okay

=usage

  $self->okay;

  $self->okay($method_name, %args);
  $self->okay($method_name);

=description

The okay method exits the program with a C<0> exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the C<handle> method so the arguments should be
key/value pairs.

=signature

okay(Maybe[Str] $name, Any %args) : ()

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok "Data::Object::Cli", "okay";

ok 1 and done_testing;
