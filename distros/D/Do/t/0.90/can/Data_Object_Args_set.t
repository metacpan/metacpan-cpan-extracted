use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

set

=usage

  $args->set(0); # undef
  $args->set('command', undef); # undef

=description

The set method takes a name or index and sets the value provided if the
associated argument exists.

=signature

set(Str $key, Maybe[Any] $value) : Any

=type

method

=cut

# TESTING

use Data::Object::Args;

can_ok "Data::Object::Args", "set";

local @ARGV = ('--command', 'post', '--action', 'users');

my $data = Data::Object::Args->new(
  named => { command => 0, action => 2 }
);

is $data->set(0), undef;
is $data->get(0), undef;
is $data->set('command', '--new-command'), '--new-command';
is $data->get(0), '--new-command';
ok !$data->set(4);

ok 1 and done_testing;
