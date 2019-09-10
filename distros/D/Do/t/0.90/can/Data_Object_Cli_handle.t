use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

handle

=usage

  $self->handle($method_name, %args);
  $self->handle($method_name);

=description

The handle method dispatches to the method whose name is provided as the first
argument. The forwarded method will receive arguments as key/value pairs. This
method injects the C<args>, C<data>, C<vars>, and C<opts> attributes as
arguments for convenience of use in the forwarded method. Any additional
arguments should be passed as key/value pairs.

=signature

handle(Str $name, Any %args) : Any

=type

method

=cut

# TESTING

use Data::Object::Cli;

can_ok "Data::Object::Cli", "handle";

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

  sub forwarded {
    my ($self, %args) = @_;

    return $args{$args{grab}};
  }

  1;
}

my $command = Command->new;

ok $command->handle('forwarded', grab => 'args');
ok $command->handle('forwarded', grab => 'data');
ok $command->handle('forwarded', grab => 'opts');
ok $command->handle('forwarded', grab => 'vars');
ok $command->handle('forwarded', grab => 'grab');

ok 1 and done_testing;
