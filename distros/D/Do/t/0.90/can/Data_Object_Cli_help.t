use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

help

=usage

  =pod help

  ...

  =cut

  my $help = $self->help

=description

The help method returns the help text documented in POD if available.

=signature

help() : ArrayRef[Str]

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok "Data::Object::Cli", "help";

{
  package Command;

  use Moo;

  extends 'Data::Object::Cli';

  sub spec {
    []
  }

  sub sign {
    {}
  }

  sub help {
    ['...']
  }

  1;
}

my $command = Command->new;

is_deeply $command->help, ['...'];

ok 1 and done_testing;
