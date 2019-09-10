use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

exit

=usage

  $self->exit(0);
  $self->exit(1);

  $self->exit($code, $method_name, %args);
  $self->exit($code, $method_name);
  $self->exit($code);

=description

The exit method exits the program using the exit code provided. The exit code
defaults to C<0>. Optionally, you can call a handler before exiting by
providing a method name with arguments. The handler will be called using the
C<handle> method so the arguments should be key/value pairs.

=signature

exit(Int $code, Maybe[Str] $name, Any %args) : ()

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok "Data::Object::Cli", "exit";

ok 1 and done_testing;
