use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

fail

=usage

  $self->fail;

  $self->fail($method_name, %args);
  $self->fail($method_name);

=description

The fail method exits the program with a C<1> exit code. Optionally, you can
call a handler before exiting by providing a method name with arguments. The
handler will be called using the C<handle> method so the arguments should be
key/value pairs.

=signature

fail(Maybe[Str] $name, Any %args) : ()

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok "Data::Object::Cli", "fail";

ok 1 and done_testing;
