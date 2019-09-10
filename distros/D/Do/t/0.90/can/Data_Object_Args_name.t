use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

name

=usage

  $args->name(0); # 0
  $args->name('command'); # 0

=description

The name method takes a name or index and returns index if the the associated
value exists.

=signature

name(Str $key) : Any

=type

method

=cut

# TESTING

use Data::Object::Args;

can_ok "Data::Object::Args", "name";

local @ARGV = ('--command', 'post', '--action', 'users');

my $data = Data::Object::Args->new(
  named => { command => 0, action => 2 }
);

is $data->name(0), 0;
is $data->name('command'), 0;
is $data->name(1), 1;
is $data->name('action'), 2;
is $data->name(2), 2;
is $data->name(3), 3;
ok !$data->name(4);

ok 1 and done_testing;
