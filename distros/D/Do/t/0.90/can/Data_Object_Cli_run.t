use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

run

=usage

  run __PACKAGE__;

=description

The run method is designed to bootstrap the program. It detects whether the
package is being invoked as a script or class and behaves accordingly. It will
be called automatically when the package is looaded if your package is
configured as recommended. This method will, if invoked as a script, call the
C<main> method passing the C<args>, C<data>, C<opts>, and C<vars> objects.

=signature

run() : Any

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok "Data::Object::Cli", "run";

{
  package Command;

  use Moo;

  extends 'Data::Object::Cli';

  my $list = [];

  sub spec {
    []
  }

  sub sign {
    {}
  }

  sub list {
    $list
  }

  sub main {
    my ($self, %args) = @_;

    push @{$list}, 'args' if exists $args{args};
    push @{$list}, 'data' if exists $args{data};
    push @{$list}, 'opts' if exists $args{opts};
    push @{$list}, 'vars' if exists $args{vars};

    return $self;
  }

  1;
}

my $command = Command->run;

isa_ok $command, 'Command';

ok $command->main;

is_deeply $command->list, ['args', 'data', 'opts', 'vars'];

ok 1 and done_testing;
