use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

sign

=usage

  =pod sign

  {command} {action}

  =cut

  $self->sign;

  # using the arguments

  $self->args->command; # $ARGV[0]
  $self->args->action; # $ARGV[1]

  $self->args->command($new_command);
  $self->args->action($new_action);

=description

The sign method returns an hashref of named C<@ARGV> positional arguments.
These named arguments are accessible as methods on the L<Data::Object::Args>
object through the C<args> attribute.

=signature

sign() : HashRef[Int]

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok "Data::Object::Cli", "sign";

{
  package Command;

  use Moo;

  extends 'Data::Object::Cli';

  sub spec {
    []
  }

  sub sign {
    { command => 0, action => 1 }
  }

  1;
}

local @ARGV = ('create', 'user');

my $command = Command->new;

my $args = $command->args;

is $args->command, 'create';
is $args->action, 'user';

ok 1 and done_testing;
